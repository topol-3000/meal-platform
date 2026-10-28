.DEFAULT_GOAL := help
OLLAMA_MODEL ?= $(shell grep -s '^OLLAMA_MODEL=' .env | cut -d= -f2)

.PHONY: help env up down ps logs db-add psql models check-telemetry lint

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

env: ## Create .env from .env.example if missing
	@test -f .env || cp .env.example .env

up: env ## Start the core and the profiles in .env (COMPOSE_PROFILES); returns when all are healthy
	docker compose up --detach --wait
	@echo "Grafana   http://localhost:3000"
	@echo "Langfuse  http://localhost:3001  (profile langfuse)"
	@echo "OTLP      http://localhost:4318"

down: ## Stop and remove the containers (the volumes are kept)
	docker compose down

ps: ## Show the containers and their health
	docker compose ps

logs: ## Follow logs: make logs [s=postgres]
	docker compose logs --follow $(s)

db-add: ## Database and user for a service, safe to repeat: make db-add name=meal-recipes
	@test -n "$(name)" || { echo "usage: make db-add name=meal-recipes"; exit 1; }
	@scripts/db-add.sh "$(name)"

psql: ## psql as the superuser: make psql [db=meal_recipes]
	docker compose exec postgres psql -U postgres -d $(or $(db),postgres)

models: ## Pull the Ollama model from .env (profile ai)
	docker compose exec ollama ollama pull $(OLLAMA_MODEL)

check-telemetry: ## Assert a service's traces, logs and metrics reached Grafana: make check-telemetry s=meal-recipes
	@test -n "$(s)" || { echo "usage: make check-telemetry s=meal-recipes"; exit 1; }
	@scripts/check-telemetry.sh "$(s)"

lint: ## Validate the compose files and the JSON contracts
	docker compose -f compose.yaml -f compose.gpu.yaml --profile ai --profile langfuse config --quiet
	python3 -c "import json,pathlib; [json.loads(p.read_text()) for p in pathlib.Path('contracts').rglob('*.json')]"
