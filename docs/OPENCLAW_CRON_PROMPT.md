# OpenClaw cron job prompt

**Single source of truth (in the OpenClaw fork):** `openclaw/skills/real-estate-cron/PROMPT.txt` and `openclaw/skills/real-estate-cron/SKILL.md`. The Slack bot (claw) can update the job via the cron tool when you ask it to — use the **real-estate-cron** skill. You can also update from the UI or CLI.

**Option A — From Slack:** Ask the bot (e.g. "Claw, update the real estate cron prompt to the latest"). The bot uses the cron tool with the canonical prompt from the real-estate-cron skill.

**Option B — From the OpenClaw UI:** Edit the **real_estate_collector** job (Cron Jobs → select job → edit). Replace the **Prompt** with the text below (same as in the fork):

---

Run the real estate data collectors: execute `/home/node/.openclaw/workspace/real_estate_ai/scripts/run_collectors.sh`. Then post a concise Slack summary to channel C0AKRSZM97H.

**Use the script output for your post:**
- The script prints `NEW_FILES_DOWNLOADED: N` and `COLLECTION_DATE: YYYY-MM-DD`. Report exactly that as "New files downloaded: N" and "Collection date: YYYY-MM-DD" (or use the line that starts with `SLACK_LINE:` verbatim).
- Include the timestamp (UTC) and any WARNING or error lines from the script under Errors/Warnings.
- Format with emojis so it's easy to scan.

**Do not** report the old six collectors (Public Records, Permits, Deeds, Foreclosures, Tax Records, Zoning) or "per category" — the script runs only the URL-based collector and the numbers are in the script output.

Optional: if you can run `git status` in the real_estate_ai workspace, you may add one line about "Nothing to commit" or "N files to commit" for GitHub; otherwise omit.

---

After saving, the next run will post the real new-file count from the URL collector to Slack.
