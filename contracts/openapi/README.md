# OpenAPI contracts

The HTTP API of each service, one file per service: `meal-recipes.json`. It is a copy of
what the service serves at `/openapi.json`:

```bash
curl -s localhost:8000/openapi.json | python3 -m json.tool > contracts/openapi/meal-recipes.json
```

A service that changes its API updates its file in the same change. A service that calls
another reads that service's file to see what it sends, and parses only the fields it uses.
