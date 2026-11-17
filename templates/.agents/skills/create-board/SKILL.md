---
name: create-board
description: Creates a new GitHub Project v2 Kanban board with all required Software Factory Status columns, links it to the repository, creates the needs-human label, and updates .agents/factory.config.json. Use when the user runs /create-board or asks to create or initialize the GitHub Project board.
---

# Create Board

Automatically provisions a GitHub Project v2 board for the current repository and wires it into `.agents/factory.config.json`.

## Steps

1. **Read Configuration**:
   - Read `.agents/factory.config.json`.
   - Check `github.owner`, `github.repo`, and `github.project_owner`.
   - If any of them still use placeholder values (`your-*`), infer `owner` and `repo` from `git remote get-url origin` (and default `project_owner` to `owner`), confirm with the user if unclear, and update `.agents/factory.config.json`.

2. **Check `gh` Authentication**:
   - Verify `gh auth status` succeeds and includes the `project` scope. If not, instruct the user to run `gh auth refresh -s project`.

3. **Run the Setup Script**:
   - On **Windows** (PowerShell):
     ```powershell
     .\.agents\setup-project.ps1
     ```
     (Pass `-Title "<title>"` if the user requested a specific board name.)
   - On **Linux / macOS**:
     ```bash
     bash .agents/setup-project.sh
     ```
     (Pass `"<title>"` as the first argument if the user requested a specific board name.)

4. **Verify & Report**:
   - Confirm `github.project_number` in `.agents/factory.config.json` is updated with the new project number.
   - Return the created GitHub Project URL and remind the user to verify the remaining settings in `.agents/factory.config.json` (such as `branch`, `coder.local_test_cmd`, and `qa.target_url`).
