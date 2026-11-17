---
name: factory-watcher
description: Polls the GitHub Project v2 Kanban board, enforces the 1-per-1 sequential lock, monitors deployment workflows, and dispatches factory-coder or factory-qa.
---

# Factory Watcher

You are the **Watcher & Dispatcher** for the headless Software Factory. Run this check deterministically on every scheduled poll.

## Step 1: Load Configuration & Board State
1. Read `.agents/factory.config.json`.
2. List items in the GitHub Project v2 board:
   ```bash
   gh project item-list <project_number> --owner <project_owner> --format json --limit 100
   ```
3. Fetch the `Status` field ID and option IDs so you can move cards between columns:
   ```bash
   gh project field-list <project_number> --owner <project_owner> --format json
   ```
4. Group items by their `status` matching `config.columns`.
   - **Ignore** `Backlog`, `Waiting User Confirmation`, and `Done`.

## Step 2: Check Active Pipeline (1-per-1 Lock)

### Case A: `Deploy` has an item
1. Check if `deploy.workflow_file` is empty (`""`):
   - If empty (local-only mode without remote deploy): move the item directly from `Deploy` to `QA` and proceed to **Case B (`QA`)**.
2. Otherwise, check the latest workflow run for `deploy.workflow_file` on `config.branch`:
   ```bash
   gh run list --repo <owner>/<repo> --workflow <deploy.workflow_file> --branch <branch> --limit 1 --json databaseId,status,conclusion,url
   ```
3. Evaluate the run:
   - If `status != "completed"`: Do nothing; wait for the next poll.
   - If `status == "completed"` and `conclusion == "success"`:
     - Move the item from `Deploy` to `QA`.
     - Proceed to **Case B (`QA`)** immediately (or invoke `factory-qa`).
   - If `status == "completed"` and `conclusion != "success"`:
     - Comment the failure details and workflow `url` on the GitHub Issue (`gh issue comment`).
     - Add label `qa.needs_human_label` (`gh issue edit <num> --add-label <label>`).
     - Move the item from `Deploy` to `Waiting User Confirmation`.
     - Stop.

### Case B: `QA` has an item
- Invoke/follow the `factory-qa` skill for that item. Stop after handling it.

### Case C: `InProgress` has an item
- Check `.agents/.factory.lock` in the workspace:
  - If `.agents/.factory.lock` exists and its `started_at` timestamp is younger than `coder.lock_ttl_minutes` (default `45` minutes): a coding task is actively running. Do **not** pick or dispatch any item. Stop.
  - If `.agents/.factory.lock` does **not** exist, or its `started_at` timestamp is older than `coder.lock_ttl_minutes` (stale lock from an interrupted run): **resume** the interrupted task by invoking/following `factory-coder` for the `InProgress` item. Stop after dispatching.

### Case D: `InProgress`, `Deploy`, and `QA` are ALL empty (0 items)
1. Check `ToDo`. If empty, stop (factory is idle).
2. Pick the **topmost** item in `ToDo` (stacking order).
3. **Ensure it is a GitHub Issue**:
   - If `content.type == "DraftIssue"`, convert it to a GitHub Issue in `owner/repo` using `gh api graphql` (`convertProjectV2DraftIssueItemToIssue` mutation with `itemId` and `repositoryId`), then re-fetch the item so you have its `issue_number`.
4. Invoke/follow the `factory-coder` skill for that issue.
