#!/usr/bin/env bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
[[ "$(uname -s)" == Darwin ]] || { echo 'This app requires macOS.' >&2; exit 1; }
for tool in git cmake xcrun curl shasum; do
  command -v "$tool" >/dev/null || { echo "Missing $tool. See README.md prerequisites." >&2; exit 1; }
done
xcrun --find swiftc >/dev/null
ROOT="$HOME/.local/share/whisper-starter"
REPO="$ROOT/whisper.cpp"
# Exact revision used in the initial M2 Max test; do not follow upstream HEAD.
REV=52a939a2a762224e255d366c1182b2af4dd1a032
EXPECTED=a03779c86df3323075f5e796cb2ce5029f00ec8869eee3fdfb897afe36c6d002
mkdir -p "$ROOT"
if [[ ! -d "$REPO" ]]; then
  git init "$REPO"
  git -C "$REPO" remote add origin https://github.com/ggml-org/whisper.cpp.git
  git -C "$REPO" fetch --depth 1 origin "$REV"
  git -C "$REPO" checkout --detach FETCH_HEAD
fi
[[ "$(git -C "$REPO" rev-parse HEAD)" == "$REV" ]] || {
  echo "Existing $REPO uses a different revision. Preserve it and ask your maintainer to reconcile versions." >&2; exit 1;
}
[[ -z "$(git -C "$REPO" status --porcelain --untracked-files=no)" ]] || {
  echo 'Whisper has tracked local modifications; review them before building.' >&2; exit 1;
}
cmake -S "$REPO" -B "$REPO/build" -DCMAKE_BUILD_TYPE=Release
cmake --build "$REPO/build" --config Release --parallel 4 --target whisper-cli
MODEL="$REPO/models/ggml-base.en.bin"
if [[ ! -f "$MODEL" ]]; then
  PART="$(mktemp "$REPO/models/base.en.download.XXXXXX")"
  trap 'rm -f "$PART"' EXIT
  curl --fail --location --retry 3 https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin -o "$PART"
  [[ "$(shasum -a 256 "$PART" | awk '{print $1}')" == "$EXPECTED" ]] || { echo 'Model checksum mismatch.' >&2; exit 1; }
  mv "$PART" "$MODEL"
  trap - EXIT
fi
[[ "$(shasum -a 256 "$MODEL" | awk '{print $1}')" == "$EXPECTED" ]] || { echo 'Existing model checksum mismatch.' >&2; exit 1; }
echo 'Whisper and model ready. Next: bash scripts/build.sh'
