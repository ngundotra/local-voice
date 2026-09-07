# Third-party components

- **whisper.cpp:** https://github.com/ggml-org/whisper.cpp — MIT licensed. Setup pins revision `52a939a2a762224e255d366c1182b2af4dd1a032`. Consult the checkout's LICENSE and bundled dependency notices for redistribution obligations.
- **Whisper base.en model:** downloaded from https://huggingface.co/ggerganov/whisper.cpp using the `ggml-base.en.bin` conversion. SHA-256: `a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002`. See the upstream [OpenAI Whisper repository](https://github.com/openai/whisper) and the model host's card/license for review. No model file is included in this repository.
- **Apple SDK frameworks and build tools:** Cocoa, AVFoundation, Carbon, Swift compiler, codesign. Supplied through Apple's developer tooling; use subject to applicable Apple terms.
- **CMake:** build-time dependency installed separately. The app does not redistribute Homebrew or CMake.

When building an enterprise distribution, include all required upstream notices for the actual binaries and dependencies shipped. This list is an inventory, not a completed legal review or software bill of materials.
