# Supabase Postgres on Fly.io

Pinned fork of `supabase/postgres` at tag `v17.6.1.121-cli` (`ed0c0e6`) for deployment to Fly.io.

**Why this fork exists**: The standard `flyio/postgres-flex` image does not ship `pgvector`. This image ships pgvector natively via Nix.

## Extensions available
- `vector` (pgvector) — 1024-dim cosine similarity search
- `pg_trgm` — trigram text search
- `pg_stat_statements`
- `postgis`, `timescaledb`, and 30+ others (see `nix/ext/`)

## Fly app: `dev-wc-ducomb-supabase-db`

### First deploy
```bash
# Create the app (first time only)
flyctl apps create dev-wc-ducomb-supabase-db --org personal

# Create the volume (10GB, ord region)
flyctl volumes create supabase_pg_data --size 10 --region ord -a dev-wc-ducomb-supabase-db

# Set the postgres password secret
flyctl secrets set POSTGRES_PASSWORD=<strong-password> -a dev-wc-ducomb-supabase-db

# Deploy
flyctl deploy --config fly.toml --app dev-wc-ducomb-supabase-db --remote-only
```

### After first deploy — create database and enable pgvector
```bash
# Proxy to the new DB
flyctl proxy 5434:5432 -a dev-wc-ducomb-supabase-db &

# Connect and set up
psql "postgresql://postgres:<password>@localhost:5434/postgres"
```

```sql
-- Create the knowledge database
CREATE DATABASE wc_ducomb_as400_metadata;
\c wc_ducomb_as400_metadata

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS vector;        -- pgvector
CREATE EXTENSION IF NOT EXISTS pg_trgm;       -- trigram search
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- Verify
SELECT extname, extversion FROM pg_extension ORDER BY extname;
```

### Migrate from dev-wc-ducomb-rag-chat-db
```bash
cd /path/to/odbc-api
./migrate.sh
```

### Update odbc-api secret after migration
```bash
flyctl secrets set \
  POSTGRES_AS400_DB_URL="postgres://postgres:<password>@dev-wc-ducomb-supabase-db.flycast:5432/wc_ducomb_as400_metadata" \
  -a dev-wc-ducomb-odbc-api
```

## Branch strategy
- `fly-deploy` — pinned at `v17.6.1.121`, our production branch. Add Fly config here.
- `develop` — upstream tracking branch (do not deploy from here).

## Upgrading the pin
To move to a new upstream release:
1. Check `supabase/postgres` tags for a new release
2. Get the commit SHA: `curl https://api.github.com/repos/supabase/postgres/git/ref/tags/vX.Y.Z`
3. Create a new branch `fly-deploy-vX.Y.Z` for testing
4. After validating, fast-forward `fly-deploy` to the new SHA
5. pg_dump → pg_restore migration if major Postgres version changes

## Supabase default users
| User | Password | Role |
|------|----------|------|
| `postgres` | `$POSTGRES_PASSWORD` | Superuser |
| `supabase_admin` | `$POSTGRES_PASSWORD` | Superuser |

Use `postgres` for application connections.
