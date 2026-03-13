# Cron job: collect data from the top 100 URLs

Each run of the collector fetches a **subset** of the top 100 real estate URLs (round-robin, 15 per run by default) and saves the extracted text into **`collected/<date>/`**. The next run continues where the last one left off.

## What runs

- **Script:** `scripts/collect_from_urls.py`
- **Runner:** `scripts/cron-collect.sh` (sets repo root and runs the script)
- **State:** `collected/.collect_state.json` (stores `last_index` for round-robin)
- **Output:** `collected/YYYY-MM-DD/<url_slug>.txt` (and `.err` on failure)

## Crontab example

Run daily at 2:00 AM:

```bash
0 2 * * * /home/you/real_estate_ai/scripts/cron-collect.sh >> /home/you/real_estate_ai/collected/cron.log 2>&1
```

Use the real path to your `real_estate_ai` repo. Ensure `python3` is on the cron PATH (or use the full path to `python3`). Optional: install `requests` for better HTTP behavior (`pip install requests`).

## Run once by hand

```bash
cd /path/to/real_estate_ai
./scripts/cron-collect.sh
# or
python3 scripts/collect_from_urls.py
```

You should see output like: `Collected 12 OK, 3 failed -> collected/2026-03-06/`
