# Enterprise deployment

## Current scope

Local Voice is a source-build prototype for macOS. An approved developer can build it per user using the README. The current distribution is **not** a signed/notarized installer, MDM package, sandboxed app, universal binary, or centrally configurable product. These capabilities are not claimed or supplied by the scripts.

## What IT needs to approve

- App source, pinned whisper.cpp revision and dependencies, and model provenance/licenses.
- Local microphone capture and retention of audio, transcripts, and diagnostic logs.
- Clipboard behavior, including enterprise clipboard tools and cross-device synchronization.
- Build tooling and initial downloads from GitHub/Hugging Face (and Homebrew if used). Internal mirrors can replace this step; runtime transcription does not require those endpoints.

The model checksum locks the bytes observed in the initial working installation; it is not an independent security audit or vendor attestation. The upstream commit is pinned for repeatability, not certified vulnerability-free. Perform your usual review before deployment.

## Managed rollout work still required

1. **Choose installation paths.** Today the app expects a runtime/model in each user's `~/.local/share/whisper-starter/whisper.cpp`. Either provision these per user or modify the app to use an approved shared, read-only runtime/model location. Merely copying the `.app` to other Macs is insufficient.
2. **Build and package the full dependency chain.** The Whisper executable loads dynamic libraries in its build output. Include and validate the required libraries and model. Review/sign all executable components as appropriate, not just the Swift launcher. Verify library paths on a clean Mac without the developer's Homebrew installation.
3. **Sign and notarize the release.** Replace the ad-hoc development signature with your organization's Developer ID workflow, configure hardened runtime and required microphone entitlement, and notarize/staple the final distribution. This repository does not have your signing credentials or provide a notarization pipeline. Apple's [Developer ID guide](https://developer.apple.com/developer-id/) and [notarization documentation](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) describe the supported distribution process.
4. **Deploy through approved management tooling.** Package the runtime, model, and app using your normal MDM/software portal process. Preserve a stable bundle identity and signing identity for updates. The current bundle ID is `local.whisperstarter.voicehotkey`; choose an organization-owned identifier before managed rollout.
5. **Validate privacy controls.** Test microphone consent under the actual macOS/MDM policy. Do not assume the app or an MDM profile can silently pregrant microphone access. Have users complete the system consent flow where required. The current global shortcut uses Carbon hotkey registration, not an Accessibility event tap.
6. **Decide retention.** This prototype saves everything until manually deleted. Implement your required retention/deletion behavior before handling work data if indefinite local retention is unacceptable. Consider backup exclusions, device encryption, and clipboard policy through existing organizational controls.
7. **Define support and updates.** Establish supported OS/architecture versions, dependency review cadence, signed updates, rollback, and a clean-device acceptance test. There is no auto-update or login-item mechanism here.

## Acceptance test

On each supported managed Mac, verify app launch under normal security controls, microphone consent, shortcut start/stop, correct input device, accurate short dictation, clipboard paste into a local editor, and microphone release after stopping/quitting. Verify a second recording, denial of microphone access, a conflicting shortcut, offline operation, and removal/update behavior. Run the automated sample check too. Do not treat the sample check as proof of live microphone or enterprise policy compatibility.

Local processing is a useful architectural property; it is not a certification of compliance with any regulatory or company policy.
