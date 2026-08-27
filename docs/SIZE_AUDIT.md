# Reproducible application-size audit

Audit reproduced: 2026-08-27. All byte values are decimal bytes unless explicitly
marked otherwise. The audited host is Apple Silicon macOS with Flutter 3.47.1,
Dart 3.13.1, Java 17, Android SDK 36, AGP 9.0.1, Gradle 9.1.0, and Kotlin
2.3.20. The production target is `lib/main_production.dart`. The reusable base
has no release signing credentials; bundletool device APKs were signed only for
local installation with the local debug key.

## Conclusion

The original size was reproducible, but it was not the irreducible Flutter
minimum. Two safe changes removed 2,070,528 bytes from every comparable APK:

1. `file_picker` 10.3.10 was upgraded to 12.1.1. The old Android graph embedded
   Apache Tika 3.2.3 (307,797 raw DEX bytes plus a 327,696-byte MIME database,
   48,590 bytes compressed). The newer plugin removed Tika and also resolves
   with the optional Maps package's `win32` graph.
2. Asset declarations became file-explicit and 28 statically and
   configuration-verified unused files were removed. The source asset tree is
   now 2,037,307 bytes instead of declaring whole template directories.

Separating Dart debug information reduces the final ARM64 APK by another
655,360 bytes and the multi-ABI AAB by 2,341,044 bytes. Symbols remain CI
artifacts; this is not obfuscation and does not replace crash symbolication.

The final external-symbol ABI-split APKs for direct distribution are ARM32
15,841,554, ARM64 18,580,390, and x86_64 19,998,578 bytes. The separately built
ARM64-only target used by the CI budget is 18,816,110 because Flutter retains
small non-target JNI packaging stubs in that analysis-compatible shape.

## Matched minimal control

The control was created outside this repository and configured with this base's
AGP 9.0.1, Gradle 9.1.0, Kotlin 2.3.20, Java 17, flavor, ABI, R8, resource
shrinking, compression and unsigned-release conditions. It used Flutter's
minimal generated `MaterialApp` and no plugins. It was moved to Trash after
measurement so it no longer occupies the workspace.

| Artifact, normal release settings | Minimal control | Optimized root | Root overhead |
| --- | ---: | ---: | ---: |
| Universal APK | 44,094,888 | 52,046,296 | 7,951,408 |
| ARM64 analyze-size APK | 15,478,966 | 19,471,470 | 3,992,504 |
| Multi-ABI AAB with external Dart symbols | 42,737,251 | 50,618,227 | 7,880,976 |
| ARM64 device `.apks` archive | 15,333,503 | 19,757,541 | 4,424,038 |
| ARM64 compressed download estimate | 6,997,861 | 9,247,946 | 2,250,085 |
| `libapp.so` / Dart AOT, decompressed | ~3 MB | 5,047,176 | ~2 MB |
| `libflutter.so`, ARM64, decompressed | 11,747,528 | 11,747,528 | 0 |
| `classes.dex`, compressed | 236,158 | 1,216,186 | 980,028 |
| `classes.dex`, raw | 524,788 | 2,481,988 | 1,957,200 |

The control is intentionally a real generated Material app rather than an
artificial empty `WidgetsApp`, so its Dart baseline is higher than the older
control. The `.apks` archive and Play compressed download are bundletool estimates, not
installed size. On the connected Samsung SM-A235F (API 34, ARM64, 450 dpi,
`en-GB`/`ar-EG`), the optimized normal-release visible code directory used
19,983 KiB. Android denied access to its optimized `/oat` directory, so that is
reported as a measured lower bound, not a fabricated exact installed total.

## Before, optimized, and distributable artifacts

| Measurement | Before | After code/assets | With external Dart symbols | Total change |
| --- | ---: | ---: | ---: | ---: |
| Universal APK | 54,116,824 | 52,046,296 | not used for Play | -2,070,528 |
| ARM64 analyze APK | 21,541,998 | 19,471,470 | 18,816,110 distribution build | -2,725,888 |
| AAB upload | 55,114,619 | 52,959,269 | 50,618,227 | -4,496,392 |
| ARM64 device `.apks` | 22,771,309 | 20,412,901 | 19,757,541 | -3,013,768 |
| ARM64 compressed download | 11,622,098 | 9,616,715 | 9,247,946 | -2,374,152 |

The external symbol files are `app.android-arm.symbols` (1,907,788),
`app.android-arm64.symbols` (2,238,752), and `app.android-x64.symbols`
(2,237,968). The release workflow also archives R8 mapping and the Android
native-debug-symbol ZIP for 90 days. A production owner must copy these into
long-term restricted storage keyed by version/build before CI retention expires.
The final reproduced Dart/R8/native set was archived outside `build/` as a
32,267,662-byte tarball with SHA-256
`9a31881ee51017299ccc5e490c81fd345ce24075eb1c2d629ba38983a78c537f`.

## Reproduced artifacts and checksums

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| Universal production APK | 52,046,296 | `dfd286d70a7f12114f7152e2541eeb2523946cd2560f63b5124ad6dde1cb4071` |
| ARM64 analyze APK | 19,471,470 | `fd8316e2a2257bcde47bac4890f4d67fafc95ea646fc7f5983af84d449bea623` |
| ARM64 target, external symbols | 18,816,110 | `c1f445e2e09eeab26ecea6cd793a6a0b08bd650830de742287c16e950bcb944b` |
| ARM32 split | 15,841,558 | `3219f79e2a2bc4a8f64fef475a44f0d46f694923634a348d993fd3d4c6267ce3` |
| ARM64 split | 18,580,390 | `d85dae196f2db620d821837259657bbeadda04875f9e4e113e8b8fbcad0cd3c7` |
| x86_64 split | 19,998,582 | `1af3f08f5b82c192e43fdea9e78e94e3f8fb6d9d791bb75e3219032c44062745` |
| AAB, external symbols | 50,618,227 | `db1dacb273040021f1836a938b389fa6d8897ad2dc62c505fd6e7fb0a04f5b37` |

The two-to-four-byte differences from the prior AAB/ARM32/x86_64 ZIPs are
archive metadata variation, not payload growth. The normal Universal and ARM64
analyze sizes are byte-identical. Removing `pretty_dio_logger` saved zero bytes
in release because its debug-only branch was already tree-shaken; it removes a
debug-data exposure risk and one dependency rather than claiming a fake size win.

## Universal APK ranked composition

| Contribution | Compressed bytes | Uncompressed bytes | APK share |
|---|---:|---:|---:|
| ARM32 libraries | 14,382,560 | 14,382,560 | 27.634% |
| ARM64 libraries | 16,926,592 | 16,926,592 | 32.522% |
| x86_64 libraries | 18,344,160 | 18,344,160 | 35.246% |
| Shared non-ABI entries | 2,220,643 | 5,060,448 | 4.267% |
| ZIP/signing/directory overhead | 172,341 | — | 0.331% |
| Total | 52,046,296 | — | 100% |

Major individual entries are `libflutter.so`: x86_64 13,051,040, ARM64
11,747,528, ARM32 8,615,468; `libapp.so`: ARM32 5,685,832, x86_64
5,178,248, ARM64 5,047,176; `classes.dex` 1,216,186 compressed / 2,481,988
raw; six Beiruti fonts 95,142–98,514 compressed each; `NOTICES.Z` 128,245;
`resources.arsc` 99,820. JNI consists of `libdartjni.so` (124,776 ARM64,
108,648 x86_64, 76,844 ARM32) and the 4,416–7,112-byte DataStore helper.
These plus two retained Lottie JSON files are every entry larger than 100 KB
uncompressed. There is one DEX file and no packaged symbol file.

To symbolize a Dart trace:

```bash
flutter symbolize \
  -i crash.txt \
  -d build/symbols/production/app.android-arm64.symbols
```

## Exact ARM64 composition

The final normal `--analyze-size` artifact is 19,471,470 bytes. Its compressed
top-level payload is:

| Owner | Compressed bytes | Notes |
| --- | ---: | --- |
| `lib/arm64-v8a` | 16,926,592 | engine, Dart AOT, JNI, DataStore native helper |
| `classes.dex` | 1,216,186 | R8-minified app/plugin Java and Kotlin |
| `assets/flutter_assets` | 748,309 | fonts, animations, SVG, translations, manifests |
| Android `res/` | 129,019 | plugin/framework resources after shrinking |
| `resources.arsc` | 99,820 | compiled resource table |
| non-target ABI stubs | 196,132 | JNI/DataStore packaging stubs in analyze artifact |
| `META-INF/androidx` | 11,340 | dependency metadata |
| Kotlin metadata/built-ins | 13,406 | Kotlin runtime metadata |
| Android manifest | 2,561 | merged production manifest |

ARM64 decompressed libraries are ranked as follows:

| Library | Bytes | Owner |
| --- | ---: | --- |
| `libflutter.so` | 11,747,528 | Flutter engine; identical to control |
| `libapp.so` | 5,047,176 | tree-shaken Dart AOT snapshot |
| `libdartjni.so` | 124,776 | `jni` transitive platform bridge |
| `libdatastore_shared_counter.so` | 7,112 | Android preferences/DataStore transitive |

No optional Firebase, notification, Maps, WebView, or Socket native library is
present. `libapp.so` is counted as Dart AOT, so the non-Dart engine/plugin native
budget is 11,879,416 bytes.

## Dart AOT package ranking

Values below are exact decompressed bytes attributed by the DevTools size JSON.
Packages absent from the table contributed no named reachable Dart AOT node in
this production entry point; their platform registrant may still contribute
native/DEX code.

| Package/library | Bytes | Package/library | Bytes |
| --- | ---: | --- | ---: |
| `flutter` | 1,417,034 | `lottie` | 362,490 |
| `hive_ce` | 109,024 | `clean_arch_base` | 96,605 |
| `material_color_utilities` | 72,498 | `flutter_localizations` | 68,843 |
| `dio` | 54,091 | `source_span` | 43,460 |
| `archive` | 41,304 | `intl` | 38,887 |
| `jni` | 38,684 | `flutter_screenutil` | 33,658 |
| `dio_cache_interceptor` | 28,895 | `cryptography` | 22,808 |
| `equatable` | 19,094 | `easy_localization` | 18,382 |
| `crypto` | 11,310 | `get_it` | 9,729 |
| `uuid` | 7,671 | `hive_ce_flutter` | 6,036 |
| `flutter_bloc` | 4,621 | `shared_preferences_android` | 4,459 |
| `path_provider_android` | 4,370 | `easy_logger` (transitive) | 4,285 |
| `flutter_secure_storage` | 4,098 | `injectable` | 2,540 |
| `connectivity_plus` | 577 | file-picker Dart platform nodes | 897 |
| image-picker Android node | 455 | URL-launcher nodes | 889 |
| video-player nodes | 1,329 | app plugin registrant | 1,502 |

The remaining Dart core/runtime/shared/stub attribution is 2,265,056 bytes.
Dominator and call-graph inspection showed the root application's 96,605-byte
node dominated by startup, network/session, shared UI, and the demo feature;
there was no optional package subtree. Treemap inspection showed Lottie as the
largest removable application-level Dart dependency, but its reachable shared
state UI is intentional, so it was retained.

## Assets and fonts

| Source group | Files | Bytes | Decision |
| --- | ---: | ---: | --- |
| Beiruti weights 200–700 | 6 | 1,747,392 | Retain weights used by typography; removed Black/ExtraBold |
| Lottie JSON | 4 | 278,789 | Retain referenced error/empty/success/visit states |
| Translation JSON | 2 | 7,987 | Retain; key parity is now tested |
| SVG icons | 4 | 3,139 | Retain referenced directional/search assets |
| Total | 16 | 2,037,307 | Below 2,100,000 source budget |

The APK's whole Flutter asset bundle is 748,309 compressed bytes. The six font
files are approximately 570 KiB compressed. Material Icons tree shaking reduced
the framework font from 1,645,184 to 1,096 bytes. No duplicate file hashes
remain in `assets/`; no raster content remains there. Android/iOS launcher and
splash assets are template placeholders and must be replaced per product.
`test/assets/asset_manifest_test.dart` prevents missing explicit assets and
Arabic/English key drift.

## Why the AAB was larger than the universal APK

The original AAB was 55,114,619 bytes versus a 54,116,824-byte universal APK.
Archive inspection accounts for the difference:

- all three Flutter engines were present and compressed: ARM64 5,478,688,
  x86_64 5,628,425, ARM32 4,741,097 bytes;
- all three Dart `libapp.so` binaries were present (about 2.0–2.31 MB compressed
  each);
- engine debug-symbol payloads were present for every ABI: ARM64 6,803,506,
  x86_64 6,618,491, ARM32 5,865,909 compressed bytes;
- Dart/app symbols contributed about 6.9 MB compressed across ABIs;
- the compressed R8 mapping was 2,193,297 bytes, DEX 1,432,307 bytes, and assets
  about 2.55 MB before optimization.

The AAB is an upload container, not a device download. It carries ABI modules,
debug metadata, and mapping required by Play tooling; a device receives only
matching splits. After optimization and external Dart symbols, the AAB is
50,618,227 bytes while the representative device receives a 9,247,946-byte
compressed payload. Engine native symbols remain legitimate AAB metadata;
separating Dart symbols does not remove Flutter's native-symbol module.

There were no development/staging assets, Firebase resources, Google services,
optional plugin registrants, duplicate fonts, or unexpected flavor resources.
R8 and `shrinkResources` are enabled, release is non-debuggable, Material icons
are tree-shaken, and release logging is disabled by policy.

## Optional package isolation and incremental cost

Root `flutter pub deps`, Gradle runtime dependencies, generated registrants,
merged manifests, iOS SwiftPM resolution, Dart AOT JSON, APK, and AAB were all
searched. The root has zero traces of Firebase Core/Messaging/Remote Config,
Awesome Notifications, Google Maps, WebView, or Socket.IO. The package sources
remain available under `packages/`, but nothing registers or initializes them
until a consumer adds the path dependency.

Each increment below was measured in a temporary copy by adding only that path
package and a minimal runtime-reachable probe, then rebuilding. The temporary
projects were deleted and the root graph was restored.

| Configuration | ARM64 APK | AAB | Estimated download | Download increment |
| --- | ---: | ---: | ---: | ---: |
| Minimal Flutter control | 13,854,285 | 40,429,312 | 6,547,255 | baseline |
| Optimized root | 19,471,470 | 52,959,269 | 9,616,715 | +3,069,460 vs control |
| Root + Notifications | 20,081,920 | 54,353,845 | 10,018,073 | +401,358 |
| Root + Remote Config | 19,549,473 | 53,230,217 | 9,694,774 | +78,059 |
| Root + WebView | 19,504,539 | 53,117,245 | 9,656,306 | +39,591 |
| Root + Maps | 19,568,833 | 53,260,168 | 9,721,733 | +105,018 |
| Root + Socket | 19,799,030 | 53,754,445 | 9,743,026 | +126,311 |

The corresponding ARM64/AAB increments are Notifications +610,450/+1,394,576;
Remote Config +78,003/+270,948; WebView +33,069/+157,976; Maps
+97,363/+300,899; and Socket +327,560/+795,176 bytes. These are toolchain and
reachability baselines, not promises about a product's full integration.

## Direct dependency disposition

“AOT” uses exact named DevTools bytes where reachable. `0 named` means Dart
tree shaking removed the package node for this minimal route; it does not mean
the dependency is free on every product screen.

| Direct dependency | Root reason | Native/transitive cost and AOT | Decision / lighter alternative |
| --- | --- | --- | --- |
| `dio` | HTTP/interceptors/cancellation | Dart; 54,091; `http_parser` | Keep; replacing mature transport locally increases risk |
| `crypto` | SHA-256 pin fingerprints | Dart; 11,310 | Keep; security primitive must not be reimplemented |
| `cryptography` | AES-256-GCM queue | Dart/FFI helpers; 22,808 | Keep; security outweighs small size |
| `dio_cache_interceptor` | opt-in scoped cache | Dart; 28,895 | Keep; built-in memory store avoids another package |
| `hive_ce` | optional local queue/cache | Dart; 109,024; path provider | Keep; persistent startup is optional |
| `hive_ce_flutter` | Flutter initialization | Dart; 6,036 | Keep with Hive; no separate native store |
| `connectivity_plus` | reachability signal | plugin; 577 plus platform code | Keep; never treated as proof of Internet |
| `intl` | locale/date/number formatting | Dart; 38,887 | Keep; SDK localization stack depends on it |
| `easy_localization` | runtime AR/EN + persistence | Dart; 18,382; prefs/logger | Keep; custom localization would cost maintenance |
| `image_picker` | Photo Picker/camera | Android/iOS plugin; 455 named | Keep; secure platform flow, no broad storage permission |
| `file_picker` | reusable document selection | Android/iOS plugin; 897 named | Keep 12.1.1; Tika-free; product may remove if unused |
| `image_cropper` | shared crop workflow | native UI; 0 named on start route | Keep compatible 11.x; optionalizing would break shared API |
| `flutter_html` | sanitized shared HTML view | Dart; 0 named on start route | Keep while widget exists; local parser is unsafe |
| `video_player` | shared media controller | native player; 1,329 named | Keep while universal media supports video |
| `cached_network_image` | cache-aware shared images | plugin/`sqflite`; 0 named root node | Keep; candidate for product removal if widget removed |
| `flutter_screenutil` | existing responsive tokens | Dart; 33,658 | Keep for compatibility; migrate deliberately, not for bytes |
| `flutter_secure_storage` | tokens/user/queue key | Keychain/Keystore/Tink; 4,098 | Keep; local replacement would be less secure |
| `equatable` | value/state equality | Dart; 19,094 | Keep; small and reduces correctness defects |
| `flutter_bloc` | state management | Dart; 4,621 plus `bloc` 3,369 | Keep; architecture standard |
| `get_it` | composition root | Dart; 9,729 | Keep at documented boundaries only |
| `injectable` | reproducible DI generation | Dart; 2,540; build-time generator | Keep; generated output is reviewed/tested |
| `flutter_svg` | shared vector assets | Dart; 0 named on start route | Keep; local SVG renderer is not viable |
| `lottie` | shared finite state animation | Dart; 362,490 + 278,789 source assets | Retain intentionally; largest app-level opportunity |
| `flutter_animate` | bounded shared transitions | Dart; 0 named on start route | Keep only for reachable components; avoid decorative overuse |
| `skeletonizer` | paginated first-load skeleton | Dart; 0 named on start route | Keep; no infinite skeleton behavior |
| `share_plus` | system share sheet | platform plugin; 0 named | Keep 13.3.0 for built-in Kotlin support |
| `url_launcher` | safe external links/schemes | platform plugin; 889 named | Keep; platform validation is not safe to reimplement |
| `rxdart` | debounce/stream coordination | Dart; 0 named on start route | Retain for existing helpers; remove with call sites only |
| `uuid` | queue/idempotency identifiers | Dart; 7,671 | Keep; local random-ID code offers no benefit |
| `dartz` | typed result compatibility | Dart; 0 named on start route | Keep until a deliberate breaking API migration |

No direct device-info, package-info, permission-handler, router, serialization,
splash-generator, or icon-generator dependency exists. Path provider,
shared-preferences/DataStore, sqflite, Tink, JNI, and platform-interface packages
are transitively owned by the capabilities listed above. Removal must include
the owning shared feature and tests, not just a `pubspec` line.

`pretty_dio_logger` was removed. A small internal interceptor records only
method, status, Dio failure type and elapsed time in debug; a regression test
proves URL, path, query, headers, bodies and response contents never appear.

## Enforceable budgets

| Metric | Baseline | Maximum | Regression allowance |
| --- | ---: | ---: | ---: |
| ARM64 APK with external symbols | 18,816,110 | 19,340,398 | 512 KiB |
| AAB with external symbols | 50,618,227 | 51,666,803 | 1 MiB |
| ARM64 Play compressed download | 9,247,946 | 9,772,234 | 512 KiB |
| Dart AOT decompressed | 5,047,176 | 5,309,320 | 256 KiB |
| Engine/plugin native, excluding Dart AOT | 11,879,416 | 12,010,560 | 128 KiB |
| Source assets + fonts | 2,037,307 | 2,100,000 | 62,693 |
| APK Flutter asset bundle | 748,309 | 870,400 | 119 KiB |

`scripts/check_size_budget.sh` enforces deterministic artifact and source-asset
budgets in CI. A measurement job can also pass `ESTIMATED_DOWNLOAD_BYTES`,
`DART_AOT_BYTES`, and `NATIVE_LIBRARY_BYTES`. Optional integrations require a
fresh incremental measurement; the table above is the baseline, and an increase
over it requires review rather than an arbitrary global limit.

## Reproduction commands

```bash
flutter build apk --release --flavor production \
  -t lib/main_production.dart --target-platform android-arm64 --analyze-size
flutter build apk --release --flavor production \
  -t lib/main_production.dart --split-per-abi
flutter build appbundle --release --flavor production \
  -t lib/main_production.dart --analyze-size

flutter build apk --release --flavor production \
  -t lib/main_production.dart --target-platform android-arm64 \
  --split-debug-info=build/symbols/production
flutter build appbundle --release --flavor production \
  -t lib/main_production.dart \
  --split-debug-info=build/symbols/production

apkanalyzer files list build/app/outputs/flutter-apk/app-production-release.apk
apkanalyzer dex packages build/app/outputs/flutter-apk/app-production-release.apk
unzip -lv build/app/outputs/bundle/productionRelease/app-production-release.aab
java -jar bundletool-all-1.18.3.jar build-apks \
  --bundle=build/app/outputs/bundle/productionRelease/app-production-release.aab \
  --output=production.apks --device-spec=arm64-device.json
java -jar bundletool-all-1.18.3.jar get-size total \
  --apks=production.apks --device-spec=arm64-device.json
```

`--analyze-size` and `--split-debug-info` cannot be combined in Flutter 3.47.1,
so analysis and distributable builds are intentionally separate. Android Studio
APK Analyzer and DevTools App Size were used as views over the same artifacts;
their rounded UI labels are not substituted for the exact archive/tool values.

## iOS limitation

The final simulator `Runner.app` is 198,116 KiB allocated (down from 205,252
KiB before this audit). It includes
simulator architectures and development/simulator framework content and is not
an App Store download estimate. The simulator bundles and SwiftPM resolution
contained only `App.framework`, `Flutter.framework`, and the expected
`objective_c.framework`; no optional Firebase, Maps, WebView, notification, or
Socket package appeared. No duplicate unexpected framework was found. A signed archive, export,
thinning, Swift-symbol stripping, and `App Thinning Size Report.txt` require a
real bundle ID, Apple team, signing certificates/profiles, and App Store export
configuration. Therefore real iOS compressed/uncompressed device sizes remain
**Blocked**, not estimated from the simulator.

## Widget-hardening release recheck — 2026-08-27

The canonical media, picker and page/widget work was rebuilt with Flutter
3.47.1 / Dart 3.13.1. No optional integration was introduced into the root Pub
graph, generated plugin registrant or APK entries. `apkanalyzer` reports the
production artifact as non-debuggable.

| Artifact | Exact bytes | SHA-256 |
| --- | ---: | --- |
| Universal APK, external Dart symbols | 49,883,940 | `0e9486b7e7bfd281694def7f951a3cf122dddce99fe34830d9288047aa1e8ecc` |
| ARM32 split APK | 15,841,890 | `3a519fb1bc303d3431af5e939c24fbd3f83fa636f8f990261ba975d71e77cf61` |
| ARM64 split APK | 18,580,722 | `21196114cff091281da7995ecbb52807060eed1f902f0bb980cf56321212d28c` |
| x86_64 split APK | 19,998,914 | `383ee453f26a57380df6d12f8bb9b92b3469e7bab9c42e5cd79bdbd37d318f1f` |
| Production AAB | 50,618,821 | `8baeafc863bb9b1251854f50a3c207c946ee4b552d5c1898d5b3e8ed61daf63c` |

The prior 52,046,296-byte universal and this 49,883,940-byte artifact use
different symbol-retention modes. The 2,162,356-byte (4.15%) difference is
therefore recorded as external-symbol packaging impact, not falsely attributed
to widget code deletion. The ARM64 analyze artifact is 19,471,802 bytes and its
DevTools data is
`~/.flutter-devtools/apk-code-size-analysis_15.json`; Flutter correctly rejects
combining `--analyze-size` with `--split-debug-info`.

The external-symbol ARM64 gate passed at 18,580,722 bytes against 19,340,398;
the AAB passed at 50,618,821 against 51,666,803. The Samsung/API 34 bundletool
compressed delivery estimate is 9,248,252 bytes. Root source assets are
2,056,847 bytes, Dart AOT is 4,391,816 bytes and external-symbol ARM64 native
libraries total 11,879,416 bytes; all pass the established budgets. Dart, R8
mapping and native symbol artifacts were retained beside the release outputs.

The authoritative post-hardening AAB measurement is **50,618,821 bytes** with
SHA-256
`8baeafc863bb9b1251854f50a3c207c946ee4b552d5c1898d5b3e8ed61daf63c`.
The earlier circulated 50,618,560-byte number is not backed by a retained final
artifact or checksum and is superseded. Historical measurements in earlier
sections remain labeled by their build phase and are not the final baseline.

## Dependency/live-test phase release recheck — 2026-08-27

After the compatible dependency-resolution update, generator hardening,
test-only gallery/integration harnesses and navigation URI fix, the complete
matrix was rebuilt with the same Flutter 3.47.1/Dart 3.13.1 production target
and `--split-debug-info=build/symbols/production` configuration used by the
post-widget artifacts above.

| Artifact | Exact bytes | SHA-256 |
| --- | ---: | --- |
| Universal APK, external Dart symbols | 49,913,424 | `cc308d0aadbdcab4723a991fa660c3640708ea1d496da97e54221d0bc79492b2` |
| ARM32 split APK | 15,838,606 | `814b77496a181404f0ac00e288b982045440c274db9b2f31471f93e07f5725eb` |
| ARM64 split APK | 18,593,822 | `41e924320dd6488926eba4d6c290fcb89df53950dfa331288eee5b80d323c37f` |
| x86_64 split APK | 20,012,014 | `6f13514752d3b2539ebce192616b67c9adf79e77e39613160382fcaaee865e33` |
| Production AAB | 50,651,242 | `5232545e2ae7cb223aa1635f38374331d9fc90f74e80485125ef8751d5c538b9` |

The comparable Universal grew 29,484 bytes (0.0591%) and the AAB grew 32,421
bytes (0.0641%) versus the authoritative post-widget artifacts. This is the
measured result of the compatible resolved dependency/code changes, not an
optional-integration leak: root dependency, generated registrant, APK-entry and
DEX checks remain clean. The ARM64 and AAB budgets passed at 18,593,822 and
50,651,242 bytes respectively; source assets remained 2,056,847 bytes.

The current authoritative AAB is therefore **50,651,242 bytes**. The
50,618,821-byte AAB remains the authoritative post-widget-hardening baseline,
not an unexplained competing measurement. Both are retained with their phase,
command configuration and checksum. The old 50,618,560-byte value remains
invalid for the reasons documented above.

`apkanalyzer` confirmed `debuggable=false` and a single `classes.dex`; the R8
mapping was produced, Material Icons were 99.9% tree-shaken, and the release
gate found no Firebase, notifications, Maps, WebView or Socket marker in the
Universal APK. The production APK is intentionally unsigned. For local runtime
smoke only, an unchanged copy was signed with an ephemeral QA certificate,
installed on Android 16, backgrounded/resumed and retried twice. It displayed
the expected bilingual controlled missing-production-config page and produced
zero fatal markers. The temporary certificate and signed copy were removed;
the checksums above are the original unsigned artifacts.
