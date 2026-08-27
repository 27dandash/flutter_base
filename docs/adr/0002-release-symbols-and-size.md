# ADR 0002: Externalize and retain release symbols

Status: Accepted — 2026-08-26

## Decision

Android production APK/AAB artifacts use `--split-debug-info` without
obfuscation. CI archives the per-ABI Dart `.symbols` files, R8 mapping, and
native-debug-symbol ZIP beside SHA-keyed release artifacts. Direct APK delivery
uses ABI splits; Google Play uses AAB. DevTools size analysis remains a separate
normal release build because Flutter does not allow `--analyze-size` together
with `--split-debug-info`.

## Consequences

The distributed ARM64 APK is 655,360 bytes smaller and the AAB is 2,341,044
bytes smaller under the audited toolchain. Crash decoding depends on preserving
the exact symbols for each version/build/ABI. CI's 90-day copy is a transfer
window, not an acceptable long-term production retention policy. Obfuscation is
a separate hardening decision and cannot be justified as a size feature.
