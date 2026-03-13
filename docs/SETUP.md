# Setup — Collectors and Dependencies

## 1. Install `jq`

The public records collector (and any script that parses `sources.json`) needs **jq** for JSON.

**Linux (Debian/Ubuntu):**
```bash
sudo apt-get update && sudo apt-get install -y jq
```

**OpenClaw Docker:** Build with jq so collector scripts work inside the container:
```bash
docker build --build-arg OPENCLAW_DOCKER_APT_PACKAGES=jq -t openclaw .
```

**Other Docker images:** Add to your Dockerfile if collectors run inside containers:
```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends jq && rm -rf /var/lib/apt/lists/*
```

**macOS:**
```bash
brew install jq
```

Verify: `jq --version`

## 2. Add data source URLs to `sources.json`

Collectors read from **sources.json**. Until you add at least one URL per category, you’ll see “no sources configured” / “no source URLs in sources.json yet”.

- Use **reputable** sources only (see [REPUTABLE_SOURCES.md](REPUTABLE_SOURCES.md)).
- Copy `sources.json.example` to `sources.json` and fill in real URLs for NC:
  - **Socrata / open data** — many NC cities/counties publish on Socrata.
  - **County recorder / Register of Deeds** — deeds, liens (often REST or bulk export).
  - **HUD** — HUD feeds where applicable.
  - **Assessor / tax** — county tax or assessor APIs/portals.
  - **GIS** — county GIS portals for parcels, zoning.

Example shape (see `sources.json.example` in the repo root):

```json
{
  "public_records": [],
  "permits": [],
  "deeds": [],
  "foreclosures": [],
  "tax_records": [],
  "zoning": []
}
```

Add URLs (strings) to each array. Scripts that use `jq` will read this file; leave an array empty if you don’t have a source yet (that collector will report “no sources configured”).

## 3. Run collectors

After `jq` is installed and `sources.json` has at least one URL for a given category, that collector can run. Public records will stop failing with “jq not installed” once `jq` is on the PATH used by `collect_public_records.sh`.
