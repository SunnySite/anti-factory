# Software Factory Rules

Always read `.agents/factory.config.json` before executing any Software Factory workflow (`factory-watcher`, `factory-coder`, or `factory-qa`).

## 1. Human-in-the-Loop Boundaries (Strict)
- **NEVER** move a card from `Backlog` to `ToDo`. Only a human may promote items from `Backlog` to `ToDo`.
- **NEVER** move a card out of `Waiting User Confirmation` (`Done` or `ToDo`). Only a human may resolve items in `Waiting User Confirmation`.

## 2. Sequential Execution Lock (1-per-1)
- **NEVER** start a new task from `ToDo` if `InProgress`, `Deploy`, or `QA` contains any item (must be 0 items across all three columns).
- Always pick the **topmost** item in `ToDo` (stacking order).

## 3. GitHub Issue Requirement
- Every active task must be a real **GitHub Issue** in `github.owner/github.repo` so QA and Coder can read and append execution logs in issue comments.
- If the topmost item in `ToDo` is a Draft Issue, `factory-watcher` must convert it to a GitHub Issue before dispatching `factory-coder`.

## 4. Branch & Merge Policy
- Always branch from and merge directly into `config.branch` (default: `development`) after `coder.local_test_cmd` passes.
- Do not open PRs for manual approval; push directly to `config.branch` to trigger `deploy.workflow_file`.

## 5. Secrets & Security
- Never commit `.env.qa`, SSH private keys, or credentials to Git.
- Deployment credentials must live exclusively in GitHub Repository Secrets.
