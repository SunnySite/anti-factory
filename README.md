<p align="center">
  <img src="assets/logo.png" alt="Anti-Factory Logo" width="520" />
</p>

# Anti-Factory (Headless Software Factory for Antigravity)

A portable **Headless Software Factory** powered by **Antigravity (`agy`)**, **GitHub Projects v2**, **GitHub Issues**, and the **`gh` CLI**.

It polls a GitHub Project v2 Kanban board, enforces a strict **1-per-1 sequential lock**, implements issues on feature branches, merges to your target branch, monitors deployment workflows, and runs automated + browser-based QA with automatic retries and human escalation.

## Prerequisites (What You Need to Prepare)

Before using `anti-factory` in a project, make sure you have:

1. **Antigravity (`agy`)**:
   - Antigravity IDE / CLI installed and signed in (`agy` available in `PATH` if using the headless runner scripts).
2. **Git & GitHub Repository**:
   - A target repository on GitHub with `origin` configured and your target branch created (default: `development`).
3. **GitHub CLI (`gh`)**:
   - Installed and authenticated with scopes `repo`, `project`, and `workflow`:
     ```bash
     gh auth login
     gh auth refresh -s repo,project,workflow
     ```
4. **OS & Project Runtime**:
   - **Windows**: PowerShell (for `setup-project.ps1`) and Command Prompt (for `run-factory.bat`).
   - **Linux / macOS**: `bash` and `python3` (for `setup-project.sh` and `run-factory.sh`).
   - **Project Toolchain**: Your project's own build/test runtime (e.g. Node.js, Python, Go, etc.) for `coder.local_test_cmd`, `qa.preview_cmd`, and `qa.test_cmd`.
5. **Deployment Server & SSH Secrets (Optional)**:
   - Only needed if using remote deployment via `.github/workflows/deploy.yml` (`deploy.workflow_file` set).
   - For local-only QA (`"workflow_file": ""`), no remote server or SSH secrets are required.

## How It Works

```text
Backlog ──(Human)──▶ ToDo ──(Coder)──▶ InProgress ──(Coder)──▶ Deploy ──(Watcher)──▶ QA ──(QA Pass)──▶ Done
                       ▲                                                              │
                       └───────────────────────(QA Fail < max_retries)────────────────┤
                                                                                      ▼ (QA Fail >= max_retries or Deploy Fail)
                                                                       Waiting User Confirmation (Human)
```

- **Human-in-the-Loop**: Only humans move cards from `Backlog` to `ToDo`, or resolve cards in `Waiting User Confirmation`.
- **1-per-1 Lock**: `factory-watcher` never starts a new `ToDo` item while `InProgress`, `Deploy`, or `QA` has any active item.

## Repository Structure

```text
.
├── .gitignore
├── LICENSE
├── README.md
├── assets/
│   └── logo.jpg
└── templates/
    ├── .agents/
    │   ├── factory.config.json       # Per-project factory configuration
    │   ├── setup-project.ps1         # Auto-create GitHub Project v2 board (Windows)
    │   ├── setup-project.sh          # Auto-create GitHub Project v2 board (Linux/macOS)
    │   ├── run-factory.bat           # Windows polling runner
    │   ├── run-factory.sh            # Linux/macOS polling runner
    │   ├── rules/
    │   │   └── AGENTS.md             # Strict factory rules & human-in-the-loop boundaries
    │   └── skills/
    │       ├── create-board/         # /create-board skill to provision GitHub Project v2
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
   - *(Optional, if using remote deploy)* Copy `templates/.github/workflows/deploy.yml` to `<your-repo>/.github/workflows/deploy.yml` and customize the build/restart commands for your stack.
2. **Configure `<your-repo>/.agents/factory.config.json`**:
   - Set `github.owner`, `github.repo`, and `github.project_owner`.
   - Set `branch` (default: `development`), `coder.local_test_cmd` (e.g. `npm test && npm run build` or `pytest`), and `deploy.workflow_file` (e.g. `deploy.yml`, or `""` for local-only QA).
   - Set `qa.target_url` and `qa.preview_cmd` (if verifying locally).
   - *(Optional)* Create `.env.qa` in `<your-repo>` (ignored by `.env.*` in `.gitignore`) if QA browser checks need login credentials.
3. **Create GitHub Project v2 Board & Label**:
   - **Via Antigravity (`/create-board`)**:
     - Run `/create-board` in Antigravity chat inside your target repository. It will infer `owner/repo` from `git remote` if still using placeholders, run the setup script, and populate `github.project_number`.
   - **Via CLI**:
     - Windows: `.\.agents\setup-project.ps1`
     - Linux/macOS: `chmod +x .agents/setup-project.sh && ./.agents/setup-project.sh`
   - **Manual**:
     - Create a GitHub Project v2 linked to your repo with `Status` options: `Backlog`, `ToDo`, `InProgress`, `Deploy`, `QA`, `Waiting User Confirmation`, `Done`.
     - Create label `needs-human` in the repository and set `github.project_number` in `factory.config.json`.
4. **Configure GitHub Secrets (if using `deploy.yml`)**:
   - In `Settings -> Secrets and variables -> Actions`, add: `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_PORT`, `DEPLOY_PATH`.
5. **Activate the Watcher**:
   - **Option A (Antigravity `/schedule`)**: Run `/schedule` in Antigravity (e.g. every 5–10 minutes) with prompt:
     ```text
     Run the factory-watcher skill against .agents/factory.config.json.
     ```
   - **Option B (Headless CLI loop)**:
     - Windows: `.agents\run-factory.bat` (or `.agents\run-factory.bat --once`)
     - Linux/macOS: `chmod +x .agents/run-factory.sh && ./.agents/run-factory.sh` (or `--once`)

## Security Notes
- `run-factory.bat` and `run-factory.sh` invoke `agy` with `--dangerously-skip-permissions` so the factory can run unattended. Only run this in trusted repositories and isolated/controlled environments.
- Never commit `.env.qa`, SSH private keys, or personal tokens.
