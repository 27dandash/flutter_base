# Reusable component lookup

The canonical catalog is `docs/REUSABLE_COMPONENT_CATALOG.md` at repository
root. Read it before creating shared UI, state, networking, session, storage,
localization, platform, or test infrastructure.

When changing a reusable public contract, update that catalog and its tests in
the same task.

For legacy image, button, state and scaffold decisions also read
`docs/WIDGET_LEGACY_MATRIX.md`. Do not revive a compatibility widget as a new
canonical contract. In particular, use `AppMediaViewerPage` instead of
`ImageView`, named `AppStateView` constructors instead of legacy empty/error
views, and `AppButton`/framework Back or Close controls instead of the legacy
button/navigation families.
