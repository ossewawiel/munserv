# System Architecture

## Stack

| Layer | Technology |
|-------|------------|
| Backend | Kotlin + Spring Boot 3 |
| Mobile | Flutter + Riverpod + Freezed |
| Web | React + TypeScript + MUI |
| Database | PostgreSQL + PostGIS |

## Key Principles

1. **Result pattern** - No exceptions for flow control
2. **Feature folders** - Group by domain, not layer
3. **Contract-first** - API specs drive implementation
4. **Immutability** - Prefer val/const, mutate via copy

## Layers

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   Mobile    │  │     Web     │  │   Backend   │
│  (Flutter)  │  │   (React)   │  │  (Kotlin)   │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       └────────────────┼────────────────┘
                        │
                   REST API
                        │
                ┌───────┴───────┐
                │   Database    │
                │  (PostgreSQL) │
                └───────────────┘
```

## See Also

- [ADRs](decisions/) - Why we chose these
- [Patterns](patterns.md) - How we code
- [API Contract](../contracts/api.md) - What we expose
