# Plugins - Agent Instructions

## Quick Reference
- **Scope**: `_plugins/**`
- **Stack**: Jekyll Ruby hooks with git CLI integration

## Key Rules (MUST follow)
```
✅ Keep hook type `:posts, :post_init`              ❌ Move logic to a non-post hook without reason
✅ Keep path interpolation quoted in git commands    ❌ Build git commands without quoting `post.path`
✅ Set `post.data['last_modified_at']`              ❌ Write to a different key and expect theme support
✅ Keep `commit_num.to_i > 1` guard                 ❌ Always overwrite last-modified for first commit
```

## Common Mistakes
- Replacing `git log` format with a non-ISO date string and producing inconsistent metadata.
- Removing the commit-count guard and adding noisy or misleading `last_modified_at` values.
- Forgetting this plugin depends on full git history in CI checkout.

## Project Layout
| Path | Purpose |
|------|---------|
| `_plugins/posts-lastmod-hook.rb` | Adds `last_modified_at` to posts based on git history |

## Quick Troubleshooting
- Symptom: Last modified date is empty or inconsistent.
  - Fix: verify the git commands still run with quoted `post.path` and ISO output.
- Symptom: Works locally, not in CI.
  - Fix: check workflow checkout depth remains `0`.

## Documentation Index
| Topic | Guide |
|-------|-------|
| Deployment checkout requirement | `.github/workflows/pages-deploy.yml` |
| Global conventions | `AGENTS.md` |
