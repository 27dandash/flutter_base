# Optional generic socket foundation

Add this package only when a product needs Socket.IO. Configure an HTTPS/WSS
endpoint and inject authentication; never put feature event names or tokens in
the generic client. The client prevents duplicate connections/listeners,
supports bounded exponential reconnect with jitter, pauses on network/app
lifecycle loss, reconnects after authentication changes, and permanently
disconnects on logout.

Register `disconnect(logout: true)` in the root `SessionCleanupRegistry` and
forward connectivity/app lifecycle changes from the consuming product. Throw
`SocketAuthenticationException` from the injected authentication provider when
credentials are unavailable or invalid; the client emits
`AppSocketState.authenticationFailed`, publishes a redacted non-retryable failure
code, and does not reconnect until `authenticationChanged()` succeeds. Logs are
not emitted by this package and payloads/authentication are never exposed.
