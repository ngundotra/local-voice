# Local Voice

A small macOS menu-bar app: press **Control–Option–Space**, talk, press it again, then paste your local Whisper transcript with **Command–V**.

No API key or cloud inference service is needed. Recording starts only after you use the shortcut or menu command. The app copies text; it does not paste automatically or send messages to Grok or any other service.

## Can I install this at work?

**Yes, if your organization approves locally built apps, microphone access, and these model weights.** This repository provides a source-build workflow suitable for an approved pilot. It is **not a turnkey enterprise installer**: builds are ad-hoc signed, not Developer ID signed or notarized, and the Whisper runtime/model are installed separately for each user.

For centrally managed deployment, have IT review [the enterprise deployment guide](docs/ENTERPRISE.md). Running locally does not override your employer's software or data policies.

## Requirements

- A Mac. The app and GPU inference were tested on an **Apple M2 Max running macOS 26.6.2**. Other Macs/macOS versions are not yet validated. Build on the target OS/architecture; there is no universal binary release.
- Apple Xcode Command Line Tools (including `swiftc`, Git, and code-signing tools).
- CMake. Homebrew is one optional way to install it; an IT-provided installation works too.
- Internet during initial setup to fetch source and the model; no network is needed by the app for transcription afterward.
- Microphone permission for **Local Voice**.
- Disk space for a roughly **148 MB model**, source/build tools, and saved recordings. Mono 16-bit 16 kHz audio uses about 1.9 MB/minute; recordings are retained until you delete them.

No Python, SDL, Accessibility permission, or account sign-in is required by the menu-bar app. It uses the default macOS microphone. English `base.en` is currently fixed in the app.

## Install from source

### 1. Install prerequisites

On a personal Mac, install Apple's tools if missing:

```bash
xcode-select --install
```

Wait for that installation to finish. If Homebrew is already installed:

```bash
HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install cmake
```

On a managed Mac, use your organization's approved developer tools instead. The project scripts do not install Homebrew, invoke sudo, change permissions in system directories, or bypass Gatekeeper.

### 2. Clone this repository

```bash
git clone https://github.com/ngundotra/local-voice.git
cd local-voice
```

This is a private repository; your GitHub account must have access. If your organization uses an internal Git mirror, clone its URL instead.

### 3. Download and build Whisper

```bash
bash scripts/setup.sh
```

This installs the runtime under `~/.local/share/whisper-starter/whisper.cpp`, builds `whisper-cli`, downloads `base.en`, and verifies its SHA-256. Source is pinned to an exact commit. Existing matching installations are reused; conflicting revisions or tracked modifications cause setup to stop rather than replace them. If a first clone/fetch was interrupted, preserve any needed files and move the incomplete runtime directory aside before retrying.

### 4. Build, check, and install the app

```bash
bash scripts/build.sh
bash scripts/check.sh
bash scripts/install.sh
open "$HOME/Applications/Local Voice.app"
```

`check.sh` transcribes the bundled JFK sample and checks for an expected phrase. It does not record your microphone or change your clipboard. Installation goes into your own `~/Applications` folder and refuses to overwrite an existing app.

If macOS or your company's security tooling blocks execution, ask IT for an approved build. Do not disable Gatekeeper or remove quarantine as an installation step.

## Use

1. Look for **🎙 Ready** in the menu bar.
2. Press **Control–Option–Space**. On first use, allow the microphone prompt.
3. Wait for **🔴 0s**, then speak.
4. Press the same shortcut to stop.
5. Wait for **✓ Copied** and a completion sound. Press **Command–V** in your desired text field.

The menu also offers Start/Stop, Open recordings and transcripts, and Quit. If the shortcut is occupied by another app, Local Voice reports the registration error; the menu remains usable. The shortcut is currently fixed in source.

Recording automatically stops at ten minutes. Clips shorter than 0.4 seconds are skipped. New recording requests during transcription are ignored with a beep. No login item is installed; reopen Local Voice after logging in.

## Privacy and saved data

Each recording creates a folder under:

```text
~/.local/share/whisper-starter/recordings/hotkey-<timestamp>-<id>/
  audio.wav
  transcript.txt
  whisper.log
```

The app creates new session directories with owner-only permissions. It does not add encryption of its own. Recordings, transcripts, and logs are retained indefinitely until you delete them; logs may include transcript text. Use **Open recordings and transcripts** to review or remove them. Existing recordings from the earlier prototype are not modified.

Successful transcription replaces the clipboard. Empty output leaves it unchanged. Clipboard history tools, Universal Clipboard, backups, or destination apps may copy data elsewhere according to their own settings. Local Voice itself has no upload, analytics, telemetry, or automatic update code. Once you paste text into an online assistant, that service's data handling applies.

Whisper can mishear names or produce words during silence. Review text before sending it.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| Microphone denied | Enable Local Voice under System Settings → Privacy & Security → Microphone. On managed Macs, IT restrictions may apply. |
| Nothing happens on shortcut | Use the menu's Start recording item. Check for a shortcut conflict and confirm the app is running. |
| Wrong microphone | Select the intended input in macOS Sound settings before recording. |
| Missing model/runtime | Run `bash scripts/setup.sh`; paths are per user, so do not run it with sudo. |
| Existing revision differs | Have your maintainer reconcile versions; setup intentionally does not reset your checkout. |
| Checksum mismatch | Do not bypass it. Have the maintainer verify the model source before changing the pinned digest. |
| Transcription fails | Open the session's `whisper.log`; the audio is retained for retry/debugging. |
| Another copy already running | Quit the earlier prototype before opening this build; two copies can contend for the shortcut. |
| Installed app already exists | Quit it and move only the old `.app` to Trash, then rerun `install.sh`. Runtime and recordings remain intact. |

## Development and validation

```text
src/VoiceHotkey.swift   App, recorder, global hotkey, Whisper subprocess, clipboard
scripts/setup.sh       Pinned runtime and verified model installation
scripts/build.sh       Native app bundle and local ad-hoc signature
scripts/check.sh       Shell syntax, bundle/signature, sample inference checks
scripts/install.sh     Per-user app installation
docs/ENTERPRISE.md     Managed deployment considerations and current gaps
```

Quit the app before rebuilding. Compilation uses the installed SDK and current architecture. The automated check verifies file transcription, not global keyboard delivery, microphone capture, or clipboard behavior. Validate those manually on each target OS with a short spoken sentence, stop the recording, and paste into a local text editor. Check that the orange system microphone indicator clears when recording stops.

## Uninstall

Quit Local Voice, then move `~/Applications/Local Voice.app` to Trash. Remove its microphone permission through system settings if desired. The runtime and saved data remain under `~/.local/share/whisper-starter`; review that folder before removing anything, especially if the original prototype still uses it.

## Dependencies and licensing

See [THIRD_PARTY.md](THIRD_PARTY.md) for source/model references. This private project does not yet declare a redistribution license for its own app code; arrange the appropriate license/ownership review before sharing outside its owner’s organization. No third-party binaries, model weights, personal recordings, or transcripts are committed here.
