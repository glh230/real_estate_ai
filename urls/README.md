# Top 100 Real Estate URLs

We keep a curated **top 100** real estate URLs. **We visit these URLs ourselves** and gather data (homes/properties, laws/regs, current events, marketing), then **store what we collect in the repo**. That corpus can later be used in **Nexus** to generate Q&A data to train **Miles** on.

## The list

- **File:** `top100_real_estate_urls.json`
- **Contents:** Up to 100 entries with `url`, `category`, `region`, and `label`.
- **Categories:** e.g. state_regulatory, county, city, deeds, tax_records, open_data, listings, federal, industry, zoning.
- **Regions:** e.g. nc (North Carolina), national.

## How the collector works

The cron runs **scripts/collect_from_urls.py** each run. It:

- Processes the **next 15 URLs in order** (0, 1, 2, … then wrap at 100).
- Saves structured text (headings, paragraphs) and binaries into **collected/&lt;date&gt;/**.
- Persists **last_index** and **cycle_complete** in **collected/.collect_state.json**. Commit this file so the next run continues from the right place (no re-scanning the same sites).

After **all 100 URLs** have been done in one cycle, **cycle_complete** is set. The collector posts in Slack: use the **OpenClaw chat interface** (or the **Real Estate URL Generator** agent/skill) to generate a new list of real estate URLs. You can save it as `top100_real_estate_urls_v2.json` and point the script at it, or replace the current file and reset `collected/.collect_state.json` to `{"last_index": 0, "cycle_complete": false}`.
