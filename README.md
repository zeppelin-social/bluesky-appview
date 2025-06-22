# the bluesky appview

This repo includes everything you need to run the Bluesky appview. It also serves a self-hosted PLC mirror and an instance of the web app.

**You'll need:**
- A domain
	- With the default settings, you'll want A records for `your.domain`, `bsky.your.domain`, and `plc.your.domain`, as well as, optionally, `api.your.domain` and `public.api.your.domain`.
- Docker, [`yq`](https://github.com/mikefarah/yq/#install)

## Setup
1. Copy `env.example` to `.env` and fill in the values.
    - You can run `scripts/gen-secrets.sh` to generate the various passwords you'll need.
2. Run `scripts/build.sh` to build the Docker images.
3. Deploy with `docker compose up -d`.


After you've got the appview running, check out [backfill-bsky](https://github.com/zeppelin-social/backfill-bsky) if you'd like to fill in historical data.

## Services

You'll be running the following services:

| Service                                                                       | Description                                                                                                                                                              |
|-------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| bsky                                                                          | The appview                                                                                                                                                              |
| [bsky-indexer](https://github.com/zeppelin-social/bsky-indexer)               | Indexes events from a relay into the appview database                                                                                                                    |
| [labelmuncher](https://github.com/zeppelin-social/labelmuncher)               | Indexes labels from labelers into the appview                                                                                                                            |
| [zplc-server](https://github.com/char/zplc-server/blob/main/src/serve-plc.ts) | A PLC directory mirror (not strictly necessary, but decent odds you'll get rate limited trying to use plc.directory)                                                     |
| [zplc-ingest](https://github.com/char/zplc-server/blob/main/src/ingest.ts)    | Exports logs from plc.directory for the mirror to serve                                                                                                                  |
| database                                                                      | The Postgres database used by the appview (this is a custom build that includes [pg_repack](https://github.com/reorg/pg_repack); can be useful to run after backfilling) |
| redis                                                                         | Redis, used by the appview and bsky-indexer                                                                                                                              |
| pgbouncer                                                                     | A connection pool for the database                                                                                                                                       |
| caddy                                                                         | Reverse proxy                                                                                                                                                            |
| social-app                                                                    | An instance of the Bluesky web app                                                                                                                                       |

---

Credit to [itaru2622](https://github.com/itaru2622/bluesky-selfhost-env) for the original repo that this is based on.
