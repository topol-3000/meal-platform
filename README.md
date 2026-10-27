# meal-platform

Local infrastructure, contracts and architecture decisions for **FamilyMeal**,
a family meal planner built as a set of small Python services.

```bash
make up          # Postgres, Redis, Grafana LGTM (+ Ollama, Langfuse via COMPOSE_PROFILES)
make models      # pull the Ollama model from .env
make help        # everything else
```

| UI | URL | Login |
|---|---|---|
| Grafana (traces, logs, metrics) | http://localhost:3000 | anonymous admin |
| Langfuse (LLM traces, prompts, evals) | http://localhost:3001 | `admin@familymeal.local` / `familymeal` |

Without an NVIDIA GPU, remove `compose.gpu.yaml` from `COMPOSE_FILE` in `.env`.
On Windows run from WSL2, or use `;` as the separator in `COMPOSE_FILE`.

To see a service in Grafana: generate it from meal-service-template, then in its repo run
`make docker-run` (joins the `meal-platform` network), call any endpoint, and run
`make check-telemetry s=<service-name>` here.

- [AGENTS.md](AGENTS.md): system map and rules
- [docs/adr](docs/adr): decisions
- [contracts](contracts): APIs and events
