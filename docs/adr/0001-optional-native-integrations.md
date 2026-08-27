# ADR 0001: Keep native integrations outside the root graph

Status: Accepted — 2026-08-26

## Decision

Notifications, Firebase Remote Config, WebView, Google Maps/location, and
Socket.IO remain independent path packages. The root may define behavior-facing
interfaces or startup hooks, but it must not import, register, initialize, or
configure their concrete plugins. Consumers opt in explicitly.

## Consequences

Unused integrations add zero Dart, DEX, native libraries, resources,
permissions, privacy declarations, or startup work. Each package owns its tests
and native lifecycle. Consumers accept an explicit integration step and must
measure the incremental binary/privacy/operational cost. A Pub workspace alone
would not create this binary boundary; dependency reachability does.
