# real_estate_ai 🏠

Automated real estate data harvester — pulls official public documents on a schedule and builds a growing dataset over time.

---

## How It Works

A cron job fires every **5 minutes**, running `scripts/run_collectors.sh`. Each collector fetches documents from configured sources, deduplicates by URL+date, saves them into the right `data/` subfolder, and then auto-commits + pushes everything to this repo.

Over time the repo becomes a rich, version-controlled archive of real estate data.

---

## Directory Structure

```
real_estate_ai/
├── scripts/
│   ├── run_collectors.sh        # Main entry point (called by cron)
│   ├── collectors/
│   │   ├── collect_public_records.sh
│   │   ├── collect_permits.sh
│   │   ├── collect_deeds.sh
│   │   ├── collect_foreclosures.sh
│   │   ├── collect_tax_records.sh
│   │   └── collect_zoning.sh
│   ├── utils/
│   │   └── helpers.sh           # Shared logging, download, git-push utils
│   └── config/
│       └── sources.json         # ← ADD YOUR DATA SOURCES HERE
├── data/
│   ├── public_records/          # County recorder docs
│   ├── permits/                 # Building permit exports
│   ├── deeds/                   # Deed transfers / sales
│   ├── foreclosures/            # Foreclosure notices
│   ├── tax_records/             # Property tax assessments
│   ├── zoning/                  # Zoning & land use data
│   └── raw/                     # Unclassified downloads (gitignored)
└── logs/
    └── collector.log            # Rolling collector log
```

---

## Adding Data Sources

Edit `scripts/config/sources.json` and add URLs under the appropriate source type:

```json
{
  "id": "my_county_deeds",
  "name": "My County Deed RSS",
  "type": "deeds",
  "enabled": true,
  "urls": [
    "https://mycounty.gov/recorder/feed/rss",
    "https://mycounty.gov/recorder/bulk/2024.csv"
  ]
}
```

**Supported types:** `public_records` · `permits` · `deeds` · `foreclosures` · `tax_records` · `zoning`

RSS/Atom feeds are detected automatically and individual document links are extracted and downloaded.

---

## Cron Schedule

Managed by OpenClaw — runs every 5 minutes automatically. No setup required.

---

## Dependencies

- `bash` 4+
- `curl`
- `jq`
- `git` (with push credentials configured)
