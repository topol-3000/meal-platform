# Adding a service

How a service generated from [meal-service-template](https://github.com/topol-3000/meal-service-template)
gets its database and, once it should run here too, its place in `compose.yaml`.
The examples use `meal-recipes` (package `meal_recipes`); replace both.

## 1. Database (services with `with_database`)

```bash
make up
make db-add name=meal-recipes
```

This creates the user `meal_recipes` with password `meal_recipes` and the database
`meal_recipes` owned by it: exactly the `DB__URL` in the service's `.env.example`.
Run it again whenever you like: what exists is left alone. Only the owner (and the
`postgres` superuser) may connect to the database, so a service can never read another
service's tables (D12).

Then, in the service:

```bash
cp .env.example .env
make migrate                      # apply the migrations
make migration name=add_recipes   # autogenerate against DB__URL, after changing models
make run
```

Services with `with_cache` use Valkey at `redis://localhost:6379/0` as is: no setup. All
services share database 0; keys start with the service name (`meal-recipes:...`).

## 2. Running it in compose

A service runs here from its image, next to a one-off `<service>-migrate` job from the
same image (D11). The job applies the migrations and exits. The app starts only after
the job has succeeded, so a failed migration stops the start instead of becoming a crash
loop, and replicas never race to migrate. Both get the same `env_file`, because
`migrate` loads the whole `Settings` (`CACHE__URL` too, when the service has a cache).

Add to `compose.yaml`, under `services:`:

```yaml
  meal-recipes-migrate:
    <<: &meal-recipes
      image: meal-recipes:dev
      build: ../meal-recipes
      env_file: services/meal-recipes.env
    command: ["python", "-m", "meal_recipes", "migrate"]
    depends_on:
      postgres:
        condition: service_healthy

  meal-recipes:
    <<: *meal-recipes
    ports:
      - "127.0.0.1:8001:8000"
    depends_on:
      meal-recipes-migrate:
        condition: service_completed_successfully
      valkey: # only with `with_cache`
        condition: service_healthy
      lgtm:
        condition: service_healthy
```

and `services/meal-recipes.env`: the service's `.env.example` with compose host names
instead of `localhost`:

```bash
ENVIRONMENT=local
LOG_LEVEL=INFO
OTEL_ENABLED=true
OTEL_EXPORTER_OTLP_ENDPOINT=http://lgtm:4318
OTEL_METRIC_EXPORT_INTERVAL=15000
DB__URL=postgresql+asyncpg://meal_recipes:meal_recipes@postgres:5432/meal_recipes
CACHE__URL=redis://valkey:6379/0
```

Then `make db-add name=meal-recipes` (once) and `make up`. Each service gets the next host
port (8001, 8002, ...); list it in the README's service table. Inside the network every
service listens on 8000, so services call each other at `http://meal-recipes:8000`.

Only variables the service reads belong in the env file; secrets of real environments
never go here (these are local credentials, like `.env.example`).

## 3. Contract

Copy the service's OpenAPI document (served at `/openapi.json`) to
`contracts/openapi/meal-recipes.json` ([contracts/openapi/](../contracts/openapi/README.md)).
