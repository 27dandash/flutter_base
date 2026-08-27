# Example — Separate Backend per Flavor

```text
{{APP_VARIANTS}} = brand A, brand B, brand C
{{FLAVORS}} = one native target per brand and environment
{{BACKEND_ENVIRONMENTS}} = separate base URL and auth realm per brand
{{COLLECTION_PATHS_OR_URLS}} = one collection/environment template per brand
{{USER_ROLES}} = role inventory per brand
```

Validate every matrix cell independently. Never reuse tokens, cache entries,
pins, endpoints, or completion claims across brands without contract evidence.
