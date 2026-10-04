# Web soundtrack companions

2026-10-04 RES1-C2-PERF. `library.json` records the four existing `src/BGM/0*.mp3` files and their unchanged Era1–4 gates. The normal native playlist still loads those project resources. Web loads metadata in the core PCK and requests the original MP3 bytes from `./audio/bgm/` only when selected for playback.

After each Godot export, run `node tools/prepare_web_compression.mjs build/web` (or the corresponding probe/preview directory). The tool copies all four source recordings byte-for-byte and records SHA256 in build/compression.json; there is no transcoding, cutting or new audio generation. `tools/start_web_server.ps1` also copies audio when Node is unavailable. Publish the audio companions together with the core export; a bare Godot export is insufficient for this Web playlist.

HTTP failure leaves gameplay running. Turning music off/on retries the selected track; disabling or selecting another track prevents an older pending response from restarting playback. Original soundtrack provenance/licensing remains with the existing source assets; this metadata and copying process does not establish new rights. Real HTTP byte comparisons and a deliberate503→menu retry are recorded in `docs/verification/res1-c2-perf.md`.
