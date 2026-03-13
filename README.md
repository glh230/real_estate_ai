# Real Estate Data Collection

We maintain a **top 100 real estate URLs** list. We **go to those URLs and gather the data ourselves**, then **store what we collect in this repo**. The goal is a growing corpus of real estate content we can use downstream (e.g. with Nexus to generate Q&A data to train Miles on).

## What we collect

- **Homes and properties** — listings, descriptions, market context.
- **Rules, laws, and regulations** — real estate law, licensing, disclosure, zoning.
- **Current events** — news and updates around real estate.
- **Marketing** — how properties and agents are marketed; copy and positioning.

## Top 100 URLs

- **List:** `urls/top100_real_estate_urls.json` (curated URLs with category, region, label).
- We **visit these URLs ourselves** and gather content into the repo (e.g. into `collected/` or similar). No external scraper bot required for the core flow — we do the collection.

## Nexus and Miles

**Nexus** can use this collected data to **generate Q&A data to train Miles on**. The flow is: we collect real estate data here → that data is used (e.g. in Nexus) to create question/answer pairs for training Miles. This repo is the **collection** side; Nexus is the **Q&A / training** side.

## Project layout

- **`urls/`** — Top 100 real estate URLs; see `urls/README.md`.
- **`collected/`** (or your chosen folder) — Raw or processed data we gather from those URLs.
- **`docs/`** — Design, setup, and source guidelines.

## Cron job

A **cron job** can run the collector on a schedule so each run fetches a **subset** of the top 100 URLs (round-robin, 15 per run) and saves text into `collected/<date>/`. See **`docs/CRON.md`** for crontab examples and **`scripts/cron-collect.sh`** as the entry point.

## Next steps

1. Run the collector by hand or via cron: `./scripts/cron-collect.sh` or `python3 scripts/collect_from_urls.py`.
2. Data lands in `collected/YYYY-MM-DD/`. When ready, feed that data into Nexus to generate Q&A for training Miles.
