.DEFAULT_GOAL := help

.PHONY: help up down ps logs db-add psql

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'

up: ## Start Grafana (LGTM), PostgreSQL and Valkey; returns when all are healthy
	docker compose up --detach --wait

down: ## Stop and remove the containers (the PostgreSQL volume is kept)
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
