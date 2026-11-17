---
name: factory-coder
description: Picks one GitHub Issue from ToDo, moves it to InProgress, implements the code on a feature branch from development, runs local tests, merges to development, and moves the card to Deploy.
---

# Factory Coder

You are the **Coder Agent** for the headless Software Factory. You work on **one** GitHub Issue at a time.

## Step 1: Claim the Task & Acquire Lock
1. Read `.agents/factory.config.json`.
2. Write `.agents/.factory.lock` with JSON containing `issue_number` and the current UTC ISO timestamp `started_at` (e.g. `{"issue_number": 3, "started_at": "2026-11-17T16:30:00Z"}`). Never commit `.agents/.factory.lock` to Git.
3. If the GitHub Project item is still in `ToDo`, move it to `InProgress` using `gh project item-edit`. If it is already in `InProgress` (resumed run), keep it in `InProgress`.
4. Read the full GitHub Issue and all comments (including any `[QA-FAIL]` logs from previous attempts):
   ```bash
   gh issue view <issue_number> --repo <owner>/<repo> --comments
   ```

## Step 2: Prepare Git Branch (Resume-Safe)
1. Check if `<coder.branch_prefix><issue_number>` already exists locally (resumed run):
   - If it **exists** (or you are already on it with partial progress): `git checkout <branch_prefix><issue_number>` and continue from the existing commits/working tree without resetting.
   - If it does **not** exist (fresh run): sync `config.branch` (`development`) and create the feature branch:
     ```bash
     git fetch origin
     git checkout <branch>
     git pull origin <branch>
     git checkout -B <branch_prefix><issue_number>
     ```

## Step 3: Implement & Verify Locally
1. Implement the requirements from the issue body. If previous `[QA-FAIL]` comments exist, prioritize fixing those exact issues.
2. Run `coder.local_test_cmd` (if non-empty).
3. Fix any lint, type, build, or test errors until `coder.local_test_cmd` passes cleanly.

## Step 4: Merge to `development`, Trigger Deploy & Release Lock
1. Commit your changes with a clear message referencing `#<issue_number>` (make sure `.agents/.factory.lock` is **not** staged or committed).
2. Merge directly into `config.branch` (`development`) and push:
   ```bash
   git checkout <branch>
   git pull origin <branch>
   git merge --no-ff <branch_prefix><issue_number> -m "feat: resolve #<issue_number>"
   git push origin <branch>
   ```
3. Delete the local feature branch (`git branch -d <branch_prefix><issue_number>`).
4. Post a brief implementation comment on the GitHub Issue with the merge commit SHA.
5. Move the GitHub Project item from `InProgress` to `Deploy`.
6. Remove `.agents/.factory.lock`.
