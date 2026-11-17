# Anti-Factory (Headless Software Factory for Antigravity)

A portable **Headless Software Factory** powered by **Antigravity (`agy`)**, **GitHub Projects v2**, **GitHub Issues**, and the **`gh` CLI**.

It polls a GitHub Project v2 Kanban board, enforces a strict **1-per-1 sequential lock**, implements issues on feature branches, merges to your target branch, monitors deployment workflows, and runs automated + browser-based QA with automatic retries and human escalation.

## Repository Structure

```text
.
├── .gitignore
├── README.md
└── templates/
    ├── .agents/
    │   ├── factory.config.json       # Per-project factory configuration
    │   ├── run-factory.bat           # Windows polling runner
    │   ├── run-factory.sh            # Linux/macOS polling runner
    │   ├── rules/
    │   │   └── AGENTS.md             # Strict factory rules & human-in-the-loop boundaries
    │   └── skills/
    │       ├── factory-watcher/      # Polls board & dispatches coder/QA
    │       ├── factory-coder/        # Implements 1 issue, tests, merges & pushes
    │       └── factory-qa/           # Runs tests & browser QA, logs results, handles retries
    └── .github/
        └── workflows/
            └── deploy.yml            # Deployment workflow template (copy to target repo)
```

## Setup Checklist per Project

1. **Copy templates into your target repository**:
   - Copy `templates/.agents/` to `<your-repo>/.agents/`
   - Copy `templates/.github/workflows/deploy.yml` to `<your-repo>/.github/workflows/deploy.yml`
2. **Edit `<your-repo>/.agents/factory.config.json`**:
   - Set `github.owner`, `github.repo`, `github.project_owner`, and `github.project_number`.
   - Set `branch` (default: `development`), `coder.local_test_cmd` (e.g. `npm test && npm run build` or `pytest`), and `deploy.workflow_file` (e.g. `deploy.yml`, or `""` for local-only QA).
   - Set `qa.target_url` and `qa.preview_cmd` (if verifying locally).
   - Optional: create `.env.qa` in `<your-repo>` (ignored by `.env.*` in `.gitignore`) if QA browser checks need login credentials.
3. **Configure GitHub Project v2 Columns**:
   - Ensure the `Status` field has:
     `Backlog`, `ToDo`, `InProgress`, `Deploy`, `QA`, `Waiting User Confirmation`, `Done`.
   - Create label `needs-human` in the repository.
4. **Configure GitHub Secrets** (`Settings -> Secrets and variables -> Actions`):
   - `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_PORT`, `DEPLOY_PATH` (or adjust to match your `deploy.yml`).
   - Never commit SSH keys or `.env.qa` to Git.
5. **Authenticate GitHub CLI**:
   - Ensure `gh auth login` (scopes: `repo`, `project`, `workflow`) is active.
6. **Activate the Watcher**:
   - **Option A (Antigravity `/schedule`)**: Run `/schedule` in Antigravity (e.g. every 5–10 minutes) with prompt:
     ```text
     Run the factory-watcher skill against .agents/factory.config.json.
     ```
   - **Option B (Headless CLI loop)**:
     - Windows: `.agents\run-factory.bat` (or `.agents\run-factory.bat --once`)
     - Linux/macOS: `chmod +x .agents/run-factory.sh && ./.agents/run-factory.sh` (or `--once`)

## Security Notes
- `run-factory.bat` and `run-factory.sh` invoke `agy` with `--dangerously-skip-permissions` so the factory can run unattended. Only run this in trusted repositories and isolated/controlled environments.
- Never commit `.env.qa`, SSH keys, or personal tokens.
