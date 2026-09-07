import Cocoa
import AVFoundation
import Carbon

let storage = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/share/whisper-starter")
let cli = storage.appendingPathComponent("whisper.cpp/build/bin/whisper-cli")
let model = storage.appendingPathComponent("whisper.cpp/models/ggml-base.en.bin")

// This same invocation is used by the app and the offline smoke test.
func transcriptionProcess(audio: URL, output: URL, log: FileHandle) -> Process {
    let p = Process()
    p.executableURL = cli
    p.arguments = ["-m", model.path, "-l", "en", "-f", audio.path, "-otxt", "-of", output.path]
    p.standardOutput = log
    p.standardError = log
    return p
}

final class VoiceApp: NSObject, NSApplicationDelegate, AVAudioRecorderDelegate {
    var item: NSStatusItem!
    var toggleItem: NSMenuItem!
    var info: NSMenuItem!
    var recorder: AVAudioRecorder?
    var process: Process?
    var session: URL?
    var timer: Timer?
    var hotkey: EventHotKeyRef?
    var eventHandler: EventHandlerRef?
    var requestingPermission = false
    var lastToggle = Date.distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "🎙 Ready"
        item.button?.toolTip = "Local Voice — Control–Option–Space to record or stop"
        let menu = NSMenu()
        info = NSMenuItem(title: "Control–Option–Space: record / stop", action: nil, keyEquivalent: "")
        menu.addItem(info)
        toggleItem = NSMenuItem(title: "Start recording", action: #selector(toggle), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        let folder = NSMenuItem(title: "Open recordings and transcripts", action: #selector(openFolder), keyEquivalent: "")
        folder.target = self
        menu.addItem(folder)
        let quit = NSMenuItem(title: "Quit Local Voice", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handlerStatus = InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context = context else { return OSStatus(eventNotHandledErr) }
            let app = Unmanaged<VoiceApp>.fromOpaque(context).takeUnretainedValue()
            app.toggle()
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        let id = EventHotKeyID(signature: 0x4C564F49, id: 1)
        let status = RegisterEventHotKey(UInt32(kVK_Space), UInt32(controlKey | optionKey), id, GetApplicationEventTarget(), 0, &hotkey)
        if handlerStatus != noErr || status != noErr {
            showError("Could not register Control–Option–Space (\(handlerStatus), \(status)). Another app may use it. You can still use the menu to record.")
        }
        if !FileManager.default.isExecutableFile(atPath: cli.path) || !FileManager.default.fileExists(atPath: model.path) {
            showError("Whisper or its base.en model is missing. Run whisper.command setup first.")
        }
    }

    func showError(_ message: String) {
        item.button?.title = "🎙 Error"
        info.title = "Error — use menu to retry"
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Local Voice"
        alert.informativeText = message
        alert.runModal()
    }

    @objc func toggle() {
        guard Date().timeIntervalSince(lastToggle) > 0.35 else { return }
        lastToggle = Date()
        guard process == nil, !requestingPermission else { NSSound.beep(); return }
        if recorder != nil { stopRecording(); return }
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: startRecording()
        case .notDetermined:
            requestingPermission = true
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    self.requestingPermission = false
                    if granted { self.startRecording() }
                    else { self.showError("Enable Local Voice in System Settings → Privacy & Security → Microphone, then try again.") }
                }
            }
        default:
            showError("Enable Local Voice in System Settings → Privacy & Security → Microphone, then try again.")
        }
    }

    func startRecording() {
        do {
            let folder = storage.appendingPathComponent("recordings/hotkey-\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString.prefix(8))")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            let r = try AVAudioRecorder(url: folder.appendingPathComponent("audio.wav"), settings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 16000.0,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ])
            r.delegate = self
            guard r.prepareToRecord(), r.record() else { throw NSError(domain: "LocalVoice", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not start the microphone."]) }
            recorder = r
            session = folder
            toggleItem.title = "Stop and transcribe"
            info.title = "Recording — Control–Option–Space to finish"
            item.button?.title = "🔴 0s"
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                guard let self = self, let recorder = self.recorder else { return }
                self.item.button?.title = "🔴 \(Int(recorder.currentTime))s"
                if recorder.currentTime >= 600 { self.stopRecording() }
            }
        } catch { showError(error.localizedDescription) }
    }

    func stopRecording() {
        guard let r = recorder, let folder = session else { return }
        let duration = r.currentTime
        r.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
        toggleItem.title = "Start recording"
        guard duration >= 0.4 else {
            item.button?.title = "🎙 Ready"
            info.title = "Clip too short; press hotkey to try again"
            return
        }
        transcribe(folder)
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        recorder.stop()
        self.recorder = nil
        timer?.invalidate()
        timer = nil
        toggleItem.title = "Start recording"
        showError(error?.localizedDescription ?? "Audio recording failed.")
    }

    func transcribe(_ folder: URL) {
        let output = folder.appendingPathComponent("transcript")
        let logURL = folder.appendingPathComponent("whisper.log")
        FileManager.default.createFile(atPath: logURL.path, contents: nil)
        do {
            let log = try FileHandle(forWritingTo: logURL)
            let p = transcriptionProcess(audio: folder.appendingPathComponent("audio.wav"), output: output, log: log)
            p.terminationHandler = { [weak self] finished in
                try? log.close()
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.process = nil
                    self.toggleItem.isEnabled = true
                    guard finished.terminationStatus == 0 else {
                        self.showError("Transcription failed. Audio is saved; see \(logURL.path)")
                        return
                    }
                    let text = ((try? String(contentsOf: output.appendingPathExtension("txt"), encoding: .utf8)) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else {
                        self.item.button?.title = "🎙 No speech"
                        self.info.title = "No text detected; clipboard unchanged"
                        return
                    }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    self.item.button?.title = "✓ Copied"
                    self.info.title = "Transcript copied — press Command–V to paste"
                    NSSound(named: "Glass")?.play()
                }
            }
            process = p
            item.button?.title = "⏳ Transcribing"
            info.title = "Transcribing locally…"
            toggleItem.isEnabled = false
            do { try p.run() }
            catch { try? log.close(); throw error }
        } catch {
            process = nil
            toggleItem.isEnabled = true
            showError(error.localizedDescription)
        }
    }

    @objc func openFolder() {
        let url = storage.appendingPathComponent("recordings")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        NSWorkspace.shared.open(url)
    }
    @objc func quitApp() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) {
        recorder?.stop()
        process?.terminate()
        if let hotkey = hotkey { UnregisterEventHotKey(hotkey) }
        if let eventHandler = eventHandler { RemoveEventHandler(eventHandler) }
    }
}

if CommandLine.arguments.count == 4 && CommandLine.arguments[1] == "--self-test" {
    let audio = URL(fileURLWithPath: CommandLine.arguments[2])
    let output = URL(fileURLWithPath: CommandLine.arguments[3])
    let p = transcriptionProcess(audio: audio, output: output, log: FileHandle.standardError)
    try p.run()
    p.waitUntilExit()
    exit(p.terminationStatus)
}
let app = NSApplication.shared
let delegate = VoiceApp()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
