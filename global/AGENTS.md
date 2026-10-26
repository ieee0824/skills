# Repository Guidelines

## Research Before Implementation

- For unfamiliar features, search GitHub for relevant open-source projects before writing code from scratch.
- Compare multiple implementations to understand established patterns, tradeoffs, and edge cases, then choose an approach that fits the current project.

## Boundary Validation

- Validate unknown values once at the boundary that owns them, such as an API handler, parser, or configuration loader.
- Convert validated input into typed values and pass those values inward.
- Do not repeat checks such as `typeof value === "object"` or property-existence tests throughout internal code.
- Do not defensively revalidate values already guaranteed by a schema, constructor, or internal type.
