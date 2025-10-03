

# This guide explains how we’ll work with branches, commits, and merges.

---

## Key Principles
- Always **branch from `main`**. This is our default branch.  
- **Avoid** large commits where possible and please include a summary if you need to do so.
- **Sync your workspace branch with `main` frequently** to avoid any merge conflicts.  
- All merges into `main` must go through **Pull Requests** and get **reviewer approval**.  

---

## Workflow

### 1. Clone repository & checkout main

git clone "repo-url"<br>
git checkout main<br>
git pull origin main

### 2. Create your branch

git checkout -b "branch-name"

### 3. Do your work (Commit and Push)
git add .<br>
git commit -m "clear commit message"<br>
git push

### 4. Raise a Pull Request
Open a PR into `main` and add a reviewer.
Address review comments if any. Once Approved, merge the PR


### Example workflow :

1. Clone the repository and switch to the `main` branch.

2. Create a new feature/workspace branch (e.g. sid_dev) from `main`.

3. Make changes in your branch, then commit and push regularly.

4. Open a PR to merge your branch into `main`.

After review and approval, the PR is merged — your changes are now in `main`.
