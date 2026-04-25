# Posts - Agent Instructions

## Quick Reference
- **Scope**: `_posts/**`
- **Commands**:
  - `bundle exec jekyll s`
  - `JEKYLL_ENV=production bundle exec jekyll b`

## Key Rules (MUST follow)
```
✅ `YYYY-MM-DD-Title.md` filename format           ❌ Arbitrary filename format
✅ Frontmatter `date` matches filename date        ❌ Filename/date mismatch
✅ Include `meta_description`, `img_path`, `image` ❌ Omit SEO/image fields
✅ Keep `meta_description` unique and 150-160 chars ❌ Reuse text or use very short descriptions
✅ Use `category:` (singular) in this repo         ❌ Switch to `categories:` without migration
✅ Add `redirect_from` when changing legacy slugs   ❌ Rename post and drop old URL
```

## Common Mistakes
- Renaming a post slug but not preserving the previous URL via `redirect_from`.
- Updating only title/date text and forgetting filename-date alignment.
- Adding image names that do not exist under the declared `img_path` folder.
- Reusing `meta_description` text across posts or writing descriptions outside the 150-160 character target.

## Project Layout
| Path | Purpose |
|------|---------|
| `_posts/*.md` | Dated blog posts with frontmatter-driven metadata |

## Quick Troubleshooting
- Symptom: Post does not appear where expected.
  - Fix: check filename date, frontmatter `date`, and timezone in `_config.yml`.
- Symptom: Broken social cards or previews.
  - Fix: validate `meta_description`, `img_path`, and `image` values.
- Symptom: Old links return 404 after a rename.
  - Fix: add or restore `redirect_from` with the old path.

## Documentation Index
| Topic | Guide |
|-------|-------|
| Global post defaults/permalink | `_config.yml` |
| Root conventions | `AGENTS.md` |
