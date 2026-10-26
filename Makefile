.DEFAULT_GOAL := help
COMPOSE := docker compose
OLLAMA_MODEL ?= $(shell grep -s '^OLLAMA_MODEL=' .env | cut -d= -f2)

.PHONY: help env up down nuke ps logs models psql redis-cli check-telemetry lint

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

env: ## Create .env from .env.example if missing
	@test -f .env || cp .env.example .env

up: env ## Start the platform (profiles from COMPOSE_PROFILES in .env)
	$(COMPOSE) up -d --wait
	@echo "Grafana   http://localhost:3000"
	@echo "Langfuse  http://localhost:3001  (if profile langfuse is on)"
	@echo "OTLP      http://localhost:4318"

down: ## Stop containers, keep data
	$(COMPOSE) down

nuke: ## Stop containers and DELETE all volumes (databases, traces, models)
	$(COMPOSE) down -v

ps: ## Container status
	$(COMPOSE) ps

logs: ## Follow logs, e.g. make logs s=lgtm
	$(COMPOSE) logs -f $(s)

models: ## Pull the Ollama model from .env (profile ai)
	$(COMPOSE) exec ollama ollama pull $(OLLAMA_MODEL)

psql: ## psql into a service DB, e.g. make psql db=recipes
	$(COMPOSE) exec postgres psql -U $(or $(db),postgres) $(or $(db),postgres)

redis-cli: ## redis-cli on the event bus
	$(COMPOSE) exec redis redis-cli

check-telemetry: ## Assert a service's traces/logs/metrics reached Grafana, e.g. make check-telemetry s=meal-recipes
	./scripts/check-telemetry.sh $(s)

lint: ## Validate compose files and schemas
	$(COMPOSE) -f compose.yaml -f compose.gpu.yaml --profile ai --profile langfuse config --quiet
	python3 -c "import json,pathlib; [json.loads(p.read_text()) for p in pathlib.Path('contracts').rglob('*.json')]"
