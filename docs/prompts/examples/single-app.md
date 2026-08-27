# Example — Single App

```text
{{PROJECT_PATH}} = /authorized/project
{{FIGMA_URLS}} = one product Figma file
{{COLLECTION_PATHS_OR_URLS}} = one test collection + environment template
{{APP_VARIANTS}} = one customer app
{{FLAVORS}} = development, staging, production
{{USER_ROLES}} = customer
{{BACKEND_ENVIRONMENTS}} = local test, staging, production (read-only audit)
{{TEST_ACCOUNTS}} = synthetic customer persona via secure handoff
```

Discovery should classify this as single app/single role and still test every
flavor; it must not create multi-app abstractions without a real need.
