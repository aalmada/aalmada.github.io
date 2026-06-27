---
name: jekyll-post-author
description: Create and edit posts in this Jekyll blog with the repository's real frontmatter format, writing style, and SEO requirements. Use this skill whenever the user asks to draft a new post, rewrite an existing post in _posts, improve title/meta_description, fix frontmatter, optimize for Google/Bing, or update redirects, tags, and categories.
---

# Jekyll Post Author

Create or edit posts in `_posts/` using this repository's real conventions.

## Trigger conditions

Use this skill for any request to draft, rewrite, or optimize blog posts, especially when the user mentions `_posts`, frontmatter, `meta_description`, title/CTR/snippets, Google/Bing SEO, redirects, tags, or categories.

## Execution contract

Always return one complete Markdown post (new file or in-place edit) that includes:

1. Valid frontmatter using the schema below.
2. A clear article body with strong structure.
3. SEO-ready `title` and `meta_description`.
4. Correct featured-image references (`img_path` and `image.path`) and valid inline image usage.

If editing an existing post, preserve intent, key links, historical context, and publication `date` unless explicitly asked to change them.

## Required frontmatter schema

Use this schema exactly, with optional fields only when needed:

```yaml
---
layout: post
read_time: true
show_date: true
title: "<post title>"
date: YYYY-MM-DD
img_path: /assets/img/posts/YYYYMMDD
image:
  path: /assets/img/posts/YYYYMMDD/<image-file>
tags: [tag1, tag2, tag3]
category: <single-category>
# redirect_from: /Old-Url.html # optional
meta_description: "<110-145 chars, specific and page-accurate>"
---
```

Schema rules:

- Required keys: `layout`, `read_time`, `show_date`, `title`, `date`, `img_path`, `image.path`, `tags`, `category`, `meta_description`.
- `redirect_from` is optional and may be a single string or YAML list.
- Keep `tags` lowercase unless technical/proper casing is required (`.net`, `csharp`, `copilot`).
- Keep `category` as one concise domain (`development`, `ai`, `network`, and similar).
- Keep image paths coherent: `img_path` is the post image directory and `image.path` points to a real image file inside it.

## Image rules

- Place post images under `/assets/img/posts/YYYYMMDD/`.
- Prefer optimized images (typically `.webp`; `.jpg`/`.jpeg`/`.png` when needed).
- Use descriptive filenames (topic-oriented, not generic camera names).
- Ensure the featured image referenced by `image.path` exists.
- For inline Markdown images, include meaningful alt text.

## Writing style for this repository

Match the established voice in `_posts`:

- Open with a strong practical framing.
- Use short-to-medium paragraphs and technical clarity.
- Prefer concrete examples over generic claims.
- Use `##` headings for major sections.
- Use numbered lists for procedures and unordered lists for grouped ideas.
- Keep tone precise, evidence-oriented, and opinionated when useful.
- Avoid fluff, keyword stuffing, and sales language.

For technical topics, include at least one realistic code/config/command snippet, explain trade-offs (not only the happy path), and add relevant internal links when useful.

Prefer inline links to related posts when mentioning concepts that are explained in depth elsewhere in this blog.

## SEO optimization rules (Google + Bing)

Apply all rules on every new or edited post:

1. Title: descriptive, concise, and aligned with page content and main heading.
2. Title: avoid boilerplate and repeated keyword variants.
3. Description: unique per post, accurate summary, meaningful specifics, no keyword lists.
4. Description length: aim for 110-145 chars; if needed, prioritize clarity/relevance over strict length.
5. Intent alignment: title, intro, section headings, and description must match one primary topic.
6. Structure: surface key information early and avoid duplicate titles/descriptions across posts.
7. Internal linking: search engines generally favor well-linked sites; add natural inline links to relevant internal posts for concepts referenced in the article.

Use `references/seo-rules.md` for the source-backed rationale and checklist.

## Workflow

For edits:

1. Read the full post (frontmatter + body).
2. Preserve `date` unless the user requests otherwise.
3. Preserve permalink compatibility via existing `redirect_from`.
4. Improve clarity, structure, and SEO fields without changing the core claim.
5. Re-check `meta_description` length and relevance after final edits.

For new posts:

1. Infer topic, audience, and intent from the prompt.
2. Propose a strong `title` and SEO-safe `meta_description`.
3. Generate frontmatter using the required schema.
4. Write with a clear narrative: problem -> approach -> details -> conclusion.

## Pre-publish checklist

Before finalizing, verify:

- Frontmatter is complete and valid YAML.
- `title` is specific and non-boilerplate.
- `meta_description` is unique, relevant, and near 110-145 chars.
- `tags` and `category` match actual content.
- `img_path` and `image.path` are valid and point to an existing featured image.
- Inline images (if any) include meaningful alt text.
- Heading hierarchy is logical.
- Links are valid and contextually useful.
- No placeholder text remains.

## Example redirect_from patterns

Single redirect:

```yaml
redirect_from: /My-Old-Post-Url.html
```

Multiple redirects:

```yaml
redirect_from:
  - /posts/My-Old-Post/
  - /My-Old-Post-Url.html
```

## Reference file

For SEO rationale and official-source notes, read:

- `references/seo-rules.md`
