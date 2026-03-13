# Real Estate Data Collection — Design

## Goal

We have a **top 100 real estate URLs** list. We **go to those URLs and gather the data ourselves** and **store what we collect in the repo**. The collected data is general real estate content: **homes/properties**, **rules/laws/regulations**, **current events**, and **marketing**. Later, **Nexus** can use this data to **generate Q&A to train Miles on** — that’s a separate use of the corpus we build here.

## What we collect

| Area | Examples |
|------|----------|
| **Homes / properties** | Listings, property details, market context |
| **Rules, laws, regulations** | Real estate law, licensing, disclosure, zoning |
| **Current events** | News, updates, trends in real estate |
| **Marketing** | How properties and agents are marketed; copy, positioning |

## Flow

1. **Top 100 list** — Curated URLs in `urls/top100_real_estate_urls.json` (categories: regulatory, county, deeds, tax records, listings, federal, industry, zoning, etc.).
2. **We gather** — We visit those URLs ourselves and pull content (scripts, manual save, or our own fetcher). No dependency on Claude Bot or another external crawler for the core collection.
3. **Store in repo** — Gathered content is saved in this repo (e.g. `collected/` with one folder or file per URL or per run) so we have a single place for the corpus.
4. **Nexus / Miles** — The collected data can be fed into **Nexus** to generate **Q&A data to train Miles on**. Nexus is the tool for turning this corpus into training material; this repo is the source of truth for what we’ve collected.

## URL list and subsets

- The top 100 can be worked through in **subsets** per run (e.g. 10–20 URLs at a time) to keep runs manageable.
- Subset strategy (by category, round-robin, or priority) is described in `urls/README.md`.

## Repo structure

- **`urls/`** — Top 100 list and how to pick subsets.
- **`collected/`** (or equivalent) — Where we store gathered data.
- **`docs/`** — This design, setup, and any source guidelines.
