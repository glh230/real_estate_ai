#!/usr/bin/env python3
"""
Cron-friendly collector: read top 100 URLs, pick a round-robin subset (spread across
the list for variety), fetch each URL, save text/PDF/images into collected/<date>/.
Errors are written to .err but ignored for counts and commit.
State (last_index) is stored in collected/.collect_state.json.
"""

from __future__ import annotations

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

# Optional: use requests if available for nicer behavior; else fallback to urllib
try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

# Subset size per run (cron run = this many URLs)
SUBSET_SIZE = 15
STATE_FILE = "collected/.collect_state.json"
URLS_FILE = "urls/top100_real_estate_urls.json"

# Extensions we save (do not commit .err)
BINARY_TYPES = {
    "application/pdf": ".pdf",
    "image/png": ".png",
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/gif": ".gif",
    "image/webp": ".webp",
}


def _strip_html(html: str) -> str:
    """Crude HTML-to-text: remove tags and collapse whitespace."""
    text = re.sub(r"<script[^>]*>.*?</script>", "", html, flags=re.DOTALL | re.IGNORECASE)
    text = re.sub(r"<style[^>]*>.*?</style>", "", text, flags=re.DOTALL | re.IGNORECASE)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"\s+", " ", text)
    return text.strip()


def _extension_from_url(url: str) -> str | None:
    """Return a file extension if URL looks like a binary asset."""
    path = (urlparse(url).path or "").lower()
    if path.endswith(".pdf"):
        return ".pdf"
    for ext in (".png", ".jpg", ".jpeg", ".gif", ".webp"):
        if path.endswith(ext):
            return ".jpg" if ext == ".jpeg" else ext
    return None


def fetch_url(url: str, timeout: int = 25) -> tuple[str | bytes | None, str | None, str | None]:
    """
    Fetch URL. Return (content, content_type_or_none, error_message).
    content is either text (str), binary (bytes), or None on failure.
    """
    if HAS_REQUESTS:
        try:
            r = requests.get(
                url,
                timeout=timeout,
                headers={"User-Agent": "RealEstateCollector/1.0"},
                stream=True,
            )
            r.raise_for_status()
            ct = (r.headers.get("Content-Type") or "").split(";")[0].strip().lower()
            if any(ct.startswith(k) for k in BINARY_TYPES):
                return (r.content, ct, None)
            return (_strip_html(r.text), ct, None)
        except requests.RequestException as e:
            return (None, None, str(e))
    else:
        try:
            from urllib.request import Request, urlopen
            req = Request(url, headers={"User-Agent": "RealEstateCollector/1.0"})
            with urlopen(req, timeout=timeout) as resp:
                ct = (resp.headers.get("Content-Type") or "").split(";")[0].strip().lower()
                raw = resp.read()
                if any(ct.startswith(k) for k in BINARY_TYPES):
                    return (raw, ct, None)
                return (_strip_html(raw.decode(errors="replace")), ct, None)
        except Exception as e:
            return (None, None, str(e))


def safe_filename(url: str, label: str | None) -> str:
    """Produce a safe filename stem from URL and optional label."""
    parsed = urlparse(url)
    netloc = re.sub(r"[^a-zA-Z0-9.-]", "_", parsed.netloc or "unknown")
    path = (parsed.path or "/").strip("/") or "index"
    path = re.sub(r"[^a-zA-Z0-9._/-]", "_", path)[:80]
    if label:
        label_clean = re.sub(r"[^a-zA-Z0-9._-]", "_", label)[:40]
        return f"{netloc}_{label_clean}" if label_clean else f"{netloc}_{path}"
    return f"{netloc}_{path}"


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    os.chdir(repo_root)

    urls_path = repo_root / URLS_FILE
    if not urls_path.exists():
        print(f"Missing {URLS_FILE}", file=sys.stderr)
        return 1

    with open(urls_path, encoding="utf-8") as f:
        data = json.load(f)
    urls_list = data.get("urls") or []
    if not urls_list:
        print("No urls in JSON", file=sys.stderr)
        return 1

    total = len(urls_list)
    state_path = repo_root / STATE_FILE
    state = {"last_index": 0}
    if state_path.exists():
        try:
            with open(state_path, encoding="utf-8") as f:
                state = json.load(f)
        except (json.JSONDecodeError, OSError):
            pass

    # Spread indices across the list so each run gets varied sources (not just first N)
    start_index = state.get("last_index", 0) % total
    step = max(1, total // SUBSET_SIZE)
    indices = [(start_index + i * step) % total for i in range(SUBSET_SIZE)]
    subset = [urls_list[i] for i in indices]

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    out_dir = repo_root / "collected" / today
    out_dir.mkdir(parents=True, exist_ok=True)

    ok, fail = 0, 0
    for entry in subset:
        url = entry.get("url") or entry.get("href")
        label = entry.get("label")
        if not url:
            continue
        content, content_type, err = fetch_url(url)
        stem = safe_filename(url, label)
        if content is not None:
            ext_from_url = _extension_from_url(url)
            if isinstance(content, bytes):
                # Binary: use Content-Type or URL to pick extension
                ext = None
                if content_type:
                    for ct, e in BINARY_TYPES.items():
                        if content_type.startswith(ct):
                            ext = e
                            break
                ext = ext or ext_from_url or ".bin"
                (out_dir / f"{stem}{ext}").write_bytes(content)
            else:
                (out_dir / f"{stem}.txt").write_text(content, encoding="utf-8")
            ok += 1
        else:
            (out_dir / f"{stem}.err").write_text(err or "unknown error", encoding="utf-8")
            fail += 1

    state["last_index"] = (start_index + SUBSET_SIZE) % total
    state["last_run"] = datetime.now(timezone.utc).isoformat()
    state_path.parent.mkdir(parents=True, exist_ok=True)
    with open(state_path, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)

    print(f"Collected {ok} OK, {fail} failed -> collected/{today}/")
    return 0 if fail == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
