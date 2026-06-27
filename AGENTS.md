# AGENTS.md

## Project type

- Static site built with Jekyll using the Chirpy theme (`jekyll-theme-chirpy`).
- Hosted on GitHub Pages.
- Primary config: `_config.yml`.

## What agents should edit

- Blog posts: `_posts/*.md`
- Top-level pages/tabs: `_tabs/*.md`
- Data files: `_data/*.yml`
- Site assets: `assets/**`
- Jekyll config and includes only when required by the task.

## Key pages and concepts

- Home page: `index.html` uses `layout: home`; avoid replacing it with custom page structure unless explicitly requested.
- About page: `_tabs/about.md` is a curated profile page. Preserve frontmatter keys like `icon` and `order` unless navigation changes are requested.
- Tab pages: `_tabs/archives.md`, `_tabs/categories.md`, `_tabs/tags.md` are collection-driven pages; keep them compatible with Chirpy and Jekyll archives behavior.
- Tabs collection concept: pages in `_tabs/` are rendered as site tabs/navigation entries; `order` controls menu ordering.
- Site identity concept: title, tagline, global description, social links, avatar, comments, and analytics are centralized in `_config.yml`.

## What agents should not edit

- Generated output: `_site/**` (build artifact, never hand-edit)
- Lockfiles or dependency files unless the task explicitly requires it.

## Post conventions

- Filename format: `YYYY-MM-DD-Title.md`.
- Posts use frontmatter and render under permalink `/posts/:title/` (from `_config.yml`).
- Keep frontmatter valid YAML.
- For this repo, `meta_description` should target `110-145` characters, prioritizing clarity if a slight deviation is needed.

## Image conventions

- Store post images under `assets/img/posts/YYYYMMDD/`.
- Non-post pages (for example `_tabs/about.md`) may use stable shared paths under `assets/img/`; preserve existing paths unless explicitly asked to reorganize.
- Keep frontmatter image fields aligned:
  - `img_path: /assets/img/posts/YYYYMMDD`
  - `image.path: /assets/img/posts/YYYYMMDD/<file>`
- Ensure the referenced featured image file exists.
- Prefer optimized images (typically `.webp`; `.jpg`/`.jpeg`/`.png` are acceptable when needed).
- Use descriptive image filenames.
- For inline Markdown images in post bodies, always provide meaningful alt text.

## Build and validation

- Local dev server:

```bash
./tools/run.sh
```

- Production build + link checks:

```bash
./tools/test.sh
```

- Prefer running validation after content or template changes.

## GitHub Pages and Chirpy constraints

- Keep changes compatible with GitHub Pages/Jekyll workflows.
- Avoid introducing custom build assumptions not present in this repository.
- Preserve Chirpy structure unless the task explicitly requires structural changes.

## Agent behavior for this repo

- Make minimal, targeted changes.
- Preserve existing writing tone and structure when editing posts.
- Do not remove redirects or SEO-critical frontmatter unless explicitly requested.
- Preserve About page voice and personal links unless the user asks for a profile rewrite.
