#!/usr/bin/env python3
"""
Cron-friendly collector: read top 100 URLs, process the next N in order each run,
fetch each URL, save structured text or binary into collected/<date>/.
State (last_index, cycle_complete) in collected/.collect_state.json; commit it so
progress persists. When a full cycle (all 100) completes, cycle_complete is set so
you can switch to a new URL list (e.g. urls/top100_real_estate_urls_v2.json).
"""

from __future__ import annotations

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

SUBSET_SIZE = 15
STATE_FILE = "collected/.collect_state.json"
URLS_FILE = "urls/top100_real_estate_urls.json"

BINARY_TYPES = {
    "application/pdf": ".pdf",
    "image/png": ".png",
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/gif": ".gif",
    "image/webp": ".webp",
}


def _html_to_structured_text(html: str) -> str:
    """
    Extract readable, structured text: headings as lines, paragraphs and lists
    separated. Reduces nav/boilerplate and avoids one giant string.
    """
    # Remove script and style
    text = re.sub(r"<script[^>]*>.*?</script>", "", html, flags=re.DOTALL | re.IGNORECASE)
    text = re.sub(r"<style[^>]*>.*?</style>", "", text, flags=re.DOTALL | re.IGNORECASE)
    # Block boundaries -> newlines so we keep structure
    text = re.sub(r"</(?:p|div|h[1-6]|li|tr|section|article|main|header|footer)\s*>", "\n", text, flags=re.IGNORECASE)
    text = re.sub(r"<(?:br|hr)\s*/?\s*>", "\n", text, flags=re.IGNORECASE)
    # Heading content on its own line (keep level)
    for level in range(1, 7):
        def repl(m):
            inner = re.sub(r"<[^>]+>", "", m.group(1))
            return "\n\n" + ("#" * level) + " " + inner.strip() + "\n\n"
        text = re.sub(
            rf"<h{level}[^>]*>(.*?)</h{level}\s*>",
            repl,
            text,
            flags=re.DOTALL | re.IGNORECASE,
        )
    # Strip remaining tags
    text = re.sub(r"<[^>]+>", " ", text)
    # Decode common entities
    text = text.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">").replace("&quot;", '"')
    text = re.sub(r"&#(\d+);", lambda m: chr(int(m.group(1))) if m.group(1).isdigit() else m.group(0), text)
    text = re.sub(r"&#x([0-9a-fA-F]+);", lambda m: chr(int(m.group(1), 16)), text)
    # Collapse whitespace but keep paragraph breaks (double newline)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n\s*\n\s*\n+", "\n\n", text)
    return text.strip()


def _extension_from_url(url: str) -> str | None:
    path = (urlparse(url).path or "").lower()
    if path.endswith(".pdf"):
        return ".pdf"
    for ext in (".png", ".jpg", ".jpeg", ".gif", ".webp"):
        if path.endswith(ext):
            return ".jpg" if ext == ".jpeg" else ext
    return None


def fetch_url(url: str, timeout: int = 25) -> tuple[str | bytes | None, str | None, str | None]:
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
            return (_html_to_structured_text(r.text), ct, None)
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
                return (_html_to_structured_text(raw.decode(errors="replace")), ct, None)
        except Exception as e:
            return (None, None, str(e))


def safe_filename(url: str, label: str | None) -> str:
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
    state = {"last_index": 0, "cycle_complete": False}
    if state_path.exists():
        try:
            with open(state_path, encoding="utf-8") as f:
                state = json.load(f)
        except (json.JSONDecodeError, OSError):
            pass

    # Next N URLs in order (0..99 then wrap)
    start_index = state.get("last_index", 0) % total
    indices = [(start_index + i) % total for i in range(SUBSET_SIZE)]
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

    # Advance: next run will do the next SUBSET_SIZE URLs
    next_index = (start_index + SUBSET_SIZE) % total
    state["last_index"] = next_index
    state["last_run"] = datetime.now(timezone.utc).isoformat()
    state["cycle_complete"] = next_index == 0 and start_index != 0  # just finished full cycle
    state_path.parent.mkdir(parents=True, exist_ok=True)
    with open(state_path, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=2)

    print(f"Collected {ok} OK, {fail} failed -> collected/{today}/ (next_index={next_index}, cycle_complete={state['cycle_complete']})")
    return 0 if fail == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
