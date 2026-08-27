# Root dependency audit

Audit date: 2026-08-27. Versions and licenses were read from the resolved local
package metadata/LICENSE files. Size and transitive ownership are detailed in
`SIZE_AUDIT.md`; the production Pub and Gradle graphs were also searched for
optional integrations.

## Production dependencies

| Dependency / resolved | Purpose and actual use | Native/security surface | License | Owner/decision |
|---|---|---|---|---|
| Flutter SDK 3.47.1 | UI/runtime/platform | Engine per ABI; framework security updates | BSD-style | Required root |
| dio 5.11.0 | HTTP, interceptors, cancellation | Network input/auth; typed mapping required | MIT | Required root |
| crypto 3.0.7 | SHA-256 pin fingerprint | Security primitive; no custom crypto | BSD-style | Required root |
| cryptography 2.9.0 | AES-256-GCM offline records | Key lifecycle/nonce/integrity sensitive | Apache-2.0 | Required root |
| dio_cache_interceptor 3.5.1 | Explicit scoped GET cache | Risk of user-data retention; never implicit | Apache-2.0 | Root; 4.x migration deferred and tested separately |
| hive_ce 2.19.3 | Optional local persistence/queue | File storage; owner isolation and migrations | BSD-style | Root capability, initialization optional |
| hive_ce_flutter 2.3.4 | Hive Flutter initialization | Path-provider bridge | BSD-style | Keep with Hive |
| connectivity_plus 7.3.1 | Reachability signal | Platform plugin; never proof of Internet | BSD-style | Required root |
| intl 0.20.3 | Date/number/locale semantics | Locale correctness, no native SDK | BSD-style | Required root |
| easy_localization 3.0.8 | Runtime AR/EN and persistence | Avoid cached strings/global context | MIT | Required root |
| image_picker 1.2.3 | Photo Picker/camera | Runtime permissions and platform lifecycle | BSD-style | Required root media contract |
| file_picker 12.1.1 | Document selection | User-selected file validation | MIT | Root reusable; product may remove with API/tests |
| image_cropper 11.0.0 | Shared crop workflow | Native UI/temporary files | BSD-style | Compatibility pin; 12.x conflicts in current Swift graph |
| flutter_html 3.0.0 | Shared sanitized rich text | Untrusted HTML/link handling | MIT | Retain while widget exists |
| video_player 2.14.0 | Shared video playback | Native codecs/network/media lifecycle | BSD-style | Retain while media contract exists |
| cached_network_image 3.4.1 | Image cache/loading | Disk/memory/network cache privacy | MIT | Root; removable with shared image widget |
| flutter_screenutil 5.9.3 | Existing responsive token compatibility | Dart only | Apache-2.0 | Retain; migrate deliberately |
| flutter_secure_storage 10.3.1 | Tokens/session/queue key | Keychain/Keystore/Tink critical | BSD-style | Required; 11.x needs planned storage migration |
| equatable 2.1.0 | State/value equality | Dart only | MIT | Required root |
| flutter_bloc 9.1.1 | State management | Dart only; lifecycle discipline | MIT | Architecture standard |
| get_it 9.2.1 | Composition-root lookup | Global-lifetime misuse risk | MIT | Composition boundary only |
| injectable 3.0.0 | Reproducible DI generation | Generated graph reviewed/tested | MIT | Root build contract |
| flutter_svg 2.3.0 | Vector assets | SVG parsing; use trusted bundled assets | MIT | Required shared UI |
| lottie 3.5.1 | Shared finite-state animation | Largest reachable Dart UI dependency | MIT | Retained intentionally |
| flutter_animate 4.5.2 | Bounded transitions | Reduced-motion/product restraint | BSD-style | Retain only for reachable components |
| skeletonizer 2.1.3 | First-page skeleton | Animation/accessibility behavior | MIT | Required shared state UI |
| share_plus 13.3.0 | System share sheet | Platform handoff; caller owns lifecycle | BSD-style | Required helper capability |
| url_launcher 6.3.2 | Validated external links | Scheme/host validation | BSD-style | Required platform adapter |
| rxdart 0.28.0 | Debounce/stream coordination | Disposal/backpressure correctness | Apache-2.0 | Retain with existing helpers |
| uuid 4.6.0 | Idempotency/queue identifiers | Not a secret or auth token | MIT | Required root |
| dartz 0.10.1 | Existing typed `Either` contracts | Old API/maintenance watch, Dart only | MIT | Retain until deliberate breaking migration |

`pretty_dio_logger` was removed. Its release size was already zero through tree
shaking, but its debug configuration exposed headers and bodies. The internal
replacement is structurally redacted and behavior-tested.

## Maintenance and vulnerability evidence

`flutter pub outdated --no-dev-dependencies` found only three constrained direct
lines: `dio_cache_interceptor` 3.5.1→4.0.7, `image_cropper` 11.0.0→12.2.1 and
`flutter_secure_storage` 10.3.1→11.0.0. The two native/security-sensitive pins
are documented compatibility/migration decisions. Cache 4.x is a breaking API
upgrade and is an upgrade task, not an unreviewed lockfile churn in this audit.

An OSV `querybatch` check of all 222 resolved hosted Pub package versions returned
zero known vulnerability records on the audit date. This is point-in-time
evidence, not proof of absence; CI should repeat it and security updates can
override normal upgrade cadence.

## Development-only dependencies

`flutter_test`, `integration_test`, `mocktail`, `bloc_test`, `build_runner`, `flutter_gen_runner`,
`injectable_generator`, `hive_ce_generator`, `flutter_lints`, and
`http_mock_adapter` are test/code-generation/lint tooling. They are absent from
release runtime graphs. Generated output is reproducible and analyzed; mocks do
not enter production code.

## Optional-absence result

The current root Pub graph, production Gradle runtime graph, generated plugin
registrant, Universal APK, DEX and AAB contain no Firebase Core/Messaging/Remote
Config, notification implementation, Google Maps, WebView, Socket.IO,
Crashlytics or analytics provider. Their source packages contribute zero bytes
until a consuming app opts in.
