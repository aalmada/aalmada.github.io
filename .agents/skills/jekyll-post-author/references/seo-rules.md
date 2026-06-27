# SEO Rules Reference (Google + Bing)

This file captures practical SEO guidance used by `jekyll-post-author`.

## Official sources

- Google Search Central, snippets and meta descriptions:
  - [Google snippets and meta descriptions](https://developers.google.com/search/docs/appearance/snippet)
- Google Search Central, title links:
  - [Google title links](https://developers.google.com/search/docs/appearance/title-link)
- Bing Webmaster Guidelines:
  - [Bing Webmaster Guidelines](https://www.bing.com/webmasters/help/webmaster-guidelines-30fba23a)

## What Google guidance says

- Google often generates snippets from page content, but may use `meta description` when it better describes the page.
- Meta descriptions should be unique per page, relevant, and descriptive.
- Avoid keyword stuffing and low-quality generic descriptions.
- There is no fixed hard character limit for meta descriptions, but snippets are truncated based on device width.
- Titles should be descriptive and concise.
- Avoid repeated boilerplate title patterns and avoid keyword stuffing.
- Keep title text aligned with visible page content and main heading.

## What Bing guidance says

- SEO fundamentals and clear HTML structure remain critical.
- Missing, duplicate, or overly short title/meta descriptions can hurt indexing reliability and visibility.
- Keep content focused, clear, and useful, with key information surfaced early.
- Align title, headings, and content intent around a single primary topic per URL.

## Repository policy applied by this skill

Because this repository uses editorial-style blog posts and the user requirement is explicit, this skill applies:

- `meta_description` target: 110-145 characters

This is a practical optimization target for readability and snippet display, not a crawler hard limit.

If meaning and accuracy conflict with strict length, prioritize relevance and clarity first.

## Fast quality checks

For each post:

1. Is title specific to the page's real topic?
2. Does description summarize the page, not just list keywords?
3. Is description unique among existing posts?
4. Are title, H1/first heading, intro paragraph, and meta description aligned?
5. Is the main value proposition visible in the first paragraph?
