# Ordered Lifecycle

```text
Requirements
    ↓
1 Create design
    ↓
2 Review completed design ── blocker ──→ revise design
    ↓
3 Review API collection ───── blocker ──→ backend questions
    ↓
4 Prove collection completeness
    ↓
Implementation using the base and canonical catalog
    ↓
5 Live Figma + collection comparison ── difference ──→ fix and re-test
    ↓
6 Final production readiness
    ↓
Per-app/flavor verdict + external release gates
```

Each stage consumes evidence from earlier stages. Skipping a stage does not
permit the next stage to assume its missing evidence.
