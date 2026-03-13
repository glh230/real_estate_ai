# Real Estate Data Collector on the OpenClaw VM

The **Slack report** (“Real Estate Data Collector — Run Complete”) is built on the **OpenClaw VM**. To show **URL collection** stats in that report (so it’s not “0 new files” for everything), do the following on the VM.

## 1. Run URL collection as part of the cron flow

In your cron flow that posts to Slack, **before** building the report:

1. `cd` to the **real_estate_ai** repo on the VM (same place that has `collect_public_records.sh`, `sources.json`, etc.).
2. Run the URL collector:
   ```bash
   python3 scripts/collect_from_urls.py
   ```
   This fetches a subset of the top 100 URLs and writes files into `collected/YYYY-MM-DD/`.

## 2. Include URL collection in the Slack “New Files Downloaded” section

After the run, get the one-line summary and include it in the message you send to Slack:

```bash
./scripts/url_collection_summary.sh
```

Example output: `URL collection: 10 new files in collected/2026-03-12/`

Add that line to the **:inbox_tray: New Files Downloaded** section of your report, e.g.:

- **URL collection:** &lt;N&gt; new files in collected/YYYY-MM-DD/
- Public Records: …
- Permits: …
- etc.

## 3. Requirements on the VM

- **Python 3** (for `collect_from_urls.py`).
- **jq** (for `url_collection_summary.sh` and any existing collect_*.sh scripts). Install with: `sudo apt-get install -y jq`
- Optional: `pip install requests` for more reliable HTTP in the URL collector.

## 4. Where things live

| What | Path (on VM) |
|------|----------------|
| URL collector | `real_estate_ai/scripts/collect_from_urls.py` |
| Summary for Slack | `real_estate_ai/scripts/url_collection_summary.sh` |
| State (round-robin index) | `real_estate_ai/collected/.collect_state.json` |
| Collected text files | `real_estate_ai/collected/YYYY-MM-DD/*.txt` |

Once the cron flow runs `collect_from_urls.py` and then includes the output of `url_collection_summary.sh` in the Slack message, the report will show real “new files” from the top-100 URL collection instead of only the legacy collectors.
