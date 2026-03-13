# OpenClaw cron job prompt

**Single source of truth (in the OpenClaw fork):** `openclaw/skills/real-estate-cron/PROMPT.txt` and `openclaw/skills/real-estate-cron/SKILL.md`. The Slack bot (claw) can update the job via the cron tool when you ask it to — use the **real-estate-cron** skill. You can also update from the UI or CLI.

## Getting changes to take effect (preferred method)

**One command, no Slack:** Edit `openclaw/skills/real-estate-cron/PROMPT.txt`, then run `cd openclaw && ./scripts/update-gcp.sh`. That syncs to the VM and runs `apply-real-estate-cron-prompt-on-vm.sh`, which applies `PROMPT.txt` to the real_estate_collector job. The job always matches the repo. To re-apply without a full sync: SSH to the VM and run `cd ~/openclaw && bash scripts/apply-real-estate-cron-prompt-on-vm.sh`.

**Previous two-step method (why it didn’t work this time):** The cron job stores its own prompt. Syncing alone does not change it. You used to need a second step (Slack or UI or VM CLI) to update the job; that’s now automated by the script above.

## Getting changes to take effect (the secret) — legacy

The cron **job** stores its own prompt. Syncing the repo to the VM only updates files on disk; it does **not** change the job’s stored message. You need **two steps**:

1. **Sync OpenClaw to the VM** so the VM has the new `PROMPT.txt` and skills:
   ```bash
   cd openclaw && ./scripts/update-gcp.sh
   ```
   (Use `source .env && ./scripts/update-gcp.sh` if you want API keys pushed too.)

2. **Update the cron job** so it uses that prompt. Do **one** of:
   - **Slack:** Ask the bot: “Update the real estate cron prompt to the latest.” (It uses the real-estate-cron skill and updates the job with the contents of PROMPT.txt.)
   - **OpenClaw UI:** Cron Jobs → select **real_estate_collector** → Edit → replace the Prompt with the contents of `openclaw/skills/real-estate-cron/PROMPT.txt` → Save.
   - **VM CLI:** SSH to the VM, then: `cd ~/openclaw && openclaw cron list` (note the job id), then `openclaw cron edit <jobId> --message "$(cat skills/real-estate-cron/PROMPT.txt)"`.

If you only do step 1, the next cron run still uses the old prompt. Always do step 2 after syncing prompt/skill changes.

**real_estate_ai repo changes** (e.g. `run_collectors.sh`): Push to GitHub, then on the VM either clone the repo into the workspace or re-sync the workspace so the VM has the new script. The cron prompt can clone the repo if the workspace is missing or not a git repo.

## What the cron does

1. Runs `run_collectors.sh` → downloads content into `collected/YYYY-MM-DD/`.
2. **Commits and pushes** the new files to GitHub (so they appear in the repo). For this to work, the real_estate_ai workspace on the VM must be a **git clone** of the repo with **push access** (SSH key or token configured).
3. Posts a Slack summary to the channel, including a **link to the collected files** (e.g. `https://github.com/glh230/real_estate_ai/tree/main/collected/2026-03-13`).

## Why collected files weren’t on GitHub before

The cron was only reporting “N files to commit” from `git status` and **not** running `git add` / `git commit` / `git push`. The prompt is now updated so the agent commits and pushes after each run. Ensure the VM workspace is a clone with push access (see above).
