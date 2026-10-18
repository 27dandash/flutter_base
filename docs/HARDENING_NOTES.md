# Hardening notes for derived projects

Behaviour a project inherits from the base that is easy to miss. Read this
before wiring a real backend.

## TLS pinning (`TLS_SHA256_PINS`)

* Comma-separated. Each pin is either the 64-hex SHA-256 of the whole
  certificate, or `spki:` followed by the SHA-256 of the public key (hex or
  base64). Prefer `spki:` pins: they survive certificate renewal while the key
  is kept.
* Production requires a primary and a backup pin; startup fails otherwise.
* Pins apply to the API `Dio` only. Third-party hosts (maps, Firebase, CDNs)
  are not pinned.

## Error reporting

`bootstrap(environment, onError: ...)` receives every uncaught error
(`fatal: true`) and recovered framework error (`fatal: false`). Wire the
product's crash reporter there. The base never passes request data or tokens.

## Notifications

Permission is requested once, through Firebase Messaging only. The local
notifications plugin never prompts. Register product notification types in
`NotificationTypeRegistry`; session-ending types bypass the user gate.

## Network and session

* Only GET requests cancel a previous request with the same key unless a call
  opts in with `cancelPrevious`.
* The offline queue retries 408/425/429 and drops other 4xx as permanent.
* A transient failure while restoring the session keeps the stored session;
  only an explicit rejection clears it. Logout clears image caches.

## Media

* Network images decode at display size (capped at 2048 px) and are cached.
* `UniversalMediaController` treats only `http`/`https` as network sources.
* `ImageHelper` returns `null` for cancel, wrong type and oversize alike. If a
  product needs to tell the user a file was too large, check the size in the
  caller or extend the helper to return a typed result.

## Known limits (decisions left to the product)

* PHP response mode and Saudi validators live in core; remove them if unused.
* Paginated dropdowns filter loaded pages locally; add server-side search per
  feature if the list is large.
* Real-device behaviour (iOS foreground local notifications, macOS keychain,
  socket and webview) is not covered by the automated suite.
