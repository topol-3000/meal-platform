# Event contracts

Transport: Redis Streams, one stream per event type, one consumer group per consuming service
(ADR 0003). Every entry is an [envelope](schemas/envelope.schema.json); `payload` is validated
by the per-event schema `schemas/<event_type>.v<version>.schema.json`.

| Event | Producer | Consumers | Schema |
|---|---|---|---|
| `recipe.import.requested` | meal-bot | meal-recipes | stage 1 |
| `recipe.imported` | meal-recipes | meal-bot | stage 1 |
| `plan.requested` | meal-bot | meal-planner | stage 2 |
| `plan.generated` | meal-planner | meal-bot | stage 2 |
| `plan.accepted` | meal-bot | meal-shopping | stage 3 |
| `shopping_list.ready` | meal-shopping | meal-bot | stage 3 |

Rules: add optional fields freely; renaming, removing or changing a field's meaning needs a
new `event_version`, and consumers accept both versions until all producers moved.
