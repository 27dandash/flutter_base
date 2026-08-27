# Example — Shared Backend

```text
{{APP_VARIANTS}} = all discovered apps/brands
{{BACKEND_ENVIRONMENTS}} = one gateway per environment, shared auth/session
{{COLLECTION_PATHS_OR_URLS}} = shared collection with explicit app/role scopes
{{USER_ROLES}} = all roles and cross-app account-switching rules
```

Prove tenant/app headers, cache keys, token audience, permissions, and account
switching. Shared infrastructure does not imply identical endpoint access.
