# Contributing to Anti-Factory

Thank you for your interest in contributing to **Anti-Factory**!

## How to Contribute

1. **Fork & Clone** the repository.
2. **Create a feature branch** from `master`:
   ```bash
   git checkout -b feat/your-feature-name
   ```
3. **Keep templates generic**:
   - Everything under `templates/` is meant to be copied into any user's project.
   - Never hardcode personal GitHub usernames, repository names, project numbers, tokens, or `.env.qa` credentials.
4. **Verify your changes**:
   - If editing PowerShell scripts (`*.ps1`), validate syntax in PowerShell.
   - If editing shell scripts (`*.sh`), ensure POSIX/Bash compatibility and `set -euo pipefail`.
   - If editing skills (`SKILL.md`), keep instructions clear, deterministic, and aligned with `templates/.agents/rules/AGENTS.md`.
5. **Open a Pull Request** targeting `master` and fill out the PR template clearly.

## Reporting Issues

- Use the **Bug Report** or **Feature Request** issue template.
- Include your OS, `gh --version`, and relevant logs (with secrets redacted).
