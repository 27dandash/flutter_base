# Template customization and upgrade guide

## Start a product safely

1. Copy the base into the product repository; preserve `pubspec.lock` initially.
2. Replace the package description, semantic version, Android namespace and all
   flavor application IDs, iOS bundle IDs, display names, launcher icons, splash
   assets, and product copy. Keep dev/staging/prod independently installable.
3. Copy `config/example.json` into ignored environment files. Supply no secret
   through Dart defines. Production needs an approved HTTPS host and overlapping
   primary/backup certificate pins.
4. Configure signing through CI secret storage and product-local Gradle/Xcode
   settings. Never place keystores, passwords, profiles, certificates, Firebase
   files, Maps keys, tokens, or real test users in the base.
5. Remove the demo `products` feature only with `scripts/remove_demo.sh`, then
   run generation, analysis, tests, and all flavor builds.
6. Add only the optional path packages the product actually enables. Follow the
   package README and `INTEGRATION_GUIDE.md`; initialize them as optional or
   non-blocking startup work.
7. Replace placeholder artwork and translations, then run the asset/key parity
   tests and size gate. Establish product-specific performance/accessibility and
   optional-package size budgets.

## Remove an unused optional module

An optional package that is not listed in the root `pubspec.yaml` already adds
zero binary size. To remove its source from a product copy:

1. Search Dart imports, generated registrants, Gradle, SwiftPM, manifests,
   plist/entitlements, Firebase scripts, DI registration, startup tasks and docs.
2. Remove product call sites and configuration first, then its path dependency.
3. Run `scripts/check_optional_resolution.sh` for every retained optional module.
4. Run root/optional analyzers and tests, all flavors, release APK/AAB, merged
   manifest inspection, and iOS resolution/build.
5. Delete the package directory only in the consuming product after those checks.
   Do not delete optional source from this reusable base merely to reduce the
   root binary—it is not packaged.

## Upgrade policy

- Commit lockfiles. Upgrade one capability group at a time and read the official
  changelog, platform requirements, privacy impact, transitive graph and native
  manifest changes.
- Run `flutter pub outdated`, root-plus-optional resolution, generation,
  formatting, analysis, tests, flavor builds, release smoke and size comparison.
- Treat Flutter/AGP/Gradle/Kotlin/Java/Android SDK as one tested toolchain. The
  Built-in Kotlin migration must include the app and incompatible plugins.
- Do not take a major upgrade just for freshness or bytes. Security,
  maintainability, platform support and migration behavior have priority.
- Version products as `major.minor.patch+monotonicBuild`. Never reuse a released
  build number. Dev/staging suffixes are not production release identities.
- Before promotion retain the previous signed artifacts/config, all Dart/native
  symbols and R8 mappings. Test through internal distribution, stage rollout,
  monitor, and roll back to the last known-good signed build/config when needed.
