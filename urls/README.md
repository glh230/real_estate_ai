# Top 100 Real Estate URLs

We keep a curated **top 100** real estate URLs. **We visit these URLs ourselves** and gather data (homes/properties, laws/regs, current events, marketing), then **store what we collect in the repo**. That corpus can later be used in **Nexus** to generate Q&A data to train **Miles** on.

## The list

- **File:** `top100_real_estate_urls.json`
- **Contents:** Up to 100 entries with `url`, `category`, `region`, and `label`.
- **Categories:** e.g. state_regulatory, county, city, deeds, tax_records, open_data, listings, federal, industry, zoning.
- **Regions:** e.g. nc (North Carolina), national.

## Gathering in subsets

You can work through the list in **subsets** each run (e.g. 10–20 URLs) to keep runs manageable:

1. **By category** — e.g. this run: only `state_regulatory` and `deeds`.
2. **By region** — e.g. this run: only `nc`, capped at 20.
3. **Random N** — e.g. 20 random URLs from the full list.
4. **Round-robin** — next 20 in order; persist an index and wrap.
5. **Priority** — high-priority URLs first, then fill up to N.

Read `top100_real_estate_urls.json`, pick your subset, then visit those URLs and save the gathered content into the repo (e.g. `collected/`).
