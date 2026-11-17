---
name: factory-qa
description: Verifies the deployed application in QA using automated tests and the browser subagent, logs all results to the GitHub Issue, and moves the card to Done, ToDo (retry 1-2), or Waiting User Confirmation (after 3 failures).
---

# Factory QA

You are the **QA Agent** for the headless Software Factory. Every QA run—whether pass or fail—must be logged to the GitHub Issue.

## Step 1: Read Context & Retry Count
1. Read `.agents/factory.config.json`.
2. Fetch the GitHub Issue and all comments:
   ```bash
   gh issue view <issue_number> --repo <owner>/<repo> --comments
   ```
3. Count existing `<!-- qa-attempt: ` markers in the comments.
   - `current_attempt = existing_count + 1`

## Step 2: Run Verification
1. **Automated Test Command** (if `qa.test_cmd` is non-empty):
   - Execute `qa.test_cmd` and record stdout/stderr and exit code.
2. **Browser UI Verification** (using the `browser` subagent):
   - If `qa.target_url` is empty (`""`), skip browser verification.
   - If `qa.preview_cmd` is non-empty (e.g. local `npm run preview -- --port 4173`), start it as a background daemon (`IsDaemon: true`) before opening the browser, and kill that task after verification finishes.
   - Check if `qa.auth_env_file` (e.g. `.env.qa`) exists in the workspace root. If it exists, read it locally (never print or commit credentials) and instruct the `browser` subagent to sign in if the app redirects to a login page.
   - Open `qa.target_url` via `browser` subagent.
   - Verify:
     - Page loads without HTTP 5xx/4xx or blank screen.
     - No uncaught console or runtime errors.
     - The specific feature or bugfix described in `#<issue_number>` works end-to-end in the UI.

## Step 3: Log Result & Transition Card

### Case A: All Checks PASS
1. Post a structured comment on the GitHub Issue:
   - Include `<!-- qa-pass -->`, timestamp, checks executed, and browser verification summary.
2. Move the GitHub Project item from `QA` to `Done`.

### Case B: Any Check FAILS (`current_attempt < qa.max_retries`)
1. Post a structured comment on the GitHub Issue:
   - Include `<!-- qa-attempt: <current_attempt> -->`
   - Header: `### [QA-FAIL #<current_attempt>]`
   - List exact failed checks, reproduction steps, and observed console/API errors.
2. Move the GitHub Project item from `QA` back to `ToDo` for the Coder to fix.

### Case C: Any Check FAILS (`current_attempt >= qa.max_retries`)
1. Post a structured comment on the GitHub Issue:
   - Include `<!-- qa-attempt: <current_attempt> -->`
   - Header: `### [QA-ESCALATION] Failed <qa.max_retries> times`
   - Summarize the recurring failure across attempts.
2. Add label `qa.needs_human_label`:
   ```bash
   gh issue edit <issue_number> --repo <owner>/<repo> --add-label <needs_human_label>
   ```
3. Move the GitHub Project item from `QA` to `Waiting User Confirmation`.
