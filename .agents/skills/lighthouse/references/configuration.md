# Lighthouse Configuration Reference

Official docs: https://developer.chrome.com/docs/lighthouse/overview  
GitHub: https://github.com/GoogleChrome/lighthouse  
Configuration docs: https://github.com/GoogleChrome/lighthouse/blob/main/docs/configuration.md

---

## Table of contents

1. [Config file structure](#config-file-structure)
2. [Settings reference](#settings-reference)
3. [Built-in audit categories](#built-in-audit-categories)
4. [Performance metrics detail](#performance-metrics-detail)
5. [SEO audits checklist](#seo-audits-checklist)
6. [Accessibility audits overview](#accessibility-audits-overview)
7. [Best practices audits overview](#best-practices-audits-overview)
8. [Throttling presets](#throttling-presets)
9. [Reference configs](#reference-configs)

---

## Config file structure

A Lighthouse config is a JavaScript module exporting an object:

```javascript
export default {
  extends: 'lighthouse:default',  // inherit default audits
  settings: { /* ... */ },
  artifacts: [ /* ... */ ],
  audits: [ /* ... */ ],
  categories: { /* ... */ },
  groups: { /* ... */ },
  plugins: [ /* ... */ ],
};
```

| Property | Type | Description |
|----------|------|-------------|
| `extends` | `"lighthouse:default"` or `undefined` | Inherit all defaults; recommended for most use cases |
| `settings` | Object | Runtime settings (categories, audits, throttling) |
| `artifacts` | `{id: string, gatherer: string}[]` | Data collectors to run |
| `audits` | `string[]` | Audit module paths (e.g., `'first-contentful-paint'`) |
| `categories` | Object | Category definitions with audit refs and weights |
| `groups` | Object | Visual grouping in the HTML report |
| `plugins` | `string[]` | Plugin npm packages to load |

### Using configs

**CLI:**
```bash
lighthouse https://example.com --config-path=./custom-config.js
```

**Node module:**
```javascript
import lighthouse from 'lighthouse';
import config from './custom-config.js';
await lighthouse('https://example.com', { port: 9222 }, config);
```

---

## Settings reference

The `settings` object controls which audits run and how the page is loaded.

### Audit selection

| Setting | Type | Description |
|---------|------|-------------|
| `onlyCategories` | string[] | Run only these categories (e.g., `['performance', 'seo']`) |
| `onlyAudits` | string[] | Run only these audits (additive with `onlyCategories`) |
| `skipAudits` | string[] | Skip these audits (takes priority over `onlyCategories`; can't be used with `onlyAudits`) |

### Throttling

| Setting | Type | Default (mobile) | Description |
|---------|------|-------------------|-------------|
| `throttlingMethod` | string | `'simulate'` | `'simulate'`, `'devtools'`, or `'provided'` |
| `throttling.cpuSlowdownMultiplier` | number | `4` | CPU slowdown factor |
| `throttling.rttMs` | number | `150` | Round-trip time in ms |
| `throttling.throughputKbps` | number | `1638.4` | Network throughput |
| `throttling.requestLatencyMs` | number | `150 * 3.75` | Request latency |
| `throttling.downloadThroughputKbps` | number | `1638.4` | Download speed |
| `throttling.uploadThroughputKbps` | number | `675` | Upload speed |

### Screen emulation

| Setting | Type | Default (mobile) | Description |
|---------|------|-------------------|-------------|
| `screenEmulation.mobile` | boolean | `true` | Emulate mobile viewport |
| `screenEmulation.width` | number | `412` | Viewport width |
| `screenEmulation.height` | number | `823` | Viewport height |
| `screenEmulation.deviceScaleFactor` | number | `1.75` | Device pixel ratio |
| `screenEmulation.disabled` | boolean | `false` | Disable all emulation |

### Other settings

| Setting | Type | Description |
|---------|------|-------------|
| `formFactor` | `'mobile'` or `'desktop'` | Affects scoring curves |
| `locale` | string | Report language (e.g., `'en-US'`) |
| `maxWaitForLoad` | number | Max wait for page load in ms |
| `logLevel` | `'silent'`, `'error'`, `'info'`, `'verbose'` | Logging verbosity |

---

## Built-in audit categories

### performance

Core Web Vitals and loading metrics. Scored as weighted average.

**Lighthouse 10 weights:**

| Metric | Weight | Audit ID |
|--------|--------|----------|
| Total Blocking Time | 30% | `total-blocking-time` |
| Largest Contentful Paint | 25% | `largest-contentful-paint` |
| Cumulative Layout Shift | 25% | `cumulative-layout-shift` |
| First Contentful Paint | 10% | `first-contentful-paint` |
| Speed Index | 10% | `speed-index` |

### accessibility

Automated checks based on axe-core. Tests color contrast, ARIA attributes, form labels, heading order, image alt text, and more. Not exhaustive — manual testing is still needed.

### best-practices

General web hygiene: HTTPS, no browser errors in console, no deprecated APIs, proper image aspect ratios, etc.

### seo

Search engine optimization basics: meta description, valid robots.txt, crawlable links, viewport meta tag, structured data, etc.

### agentic-browsing

Whether the page provides signals that help AI agents navigate and interact with it.

---

## Performance metrics detail

### First Contentful Paint (FCP)

- **Measures**: Time until the first text or image pixel is rendered
- **Good**: < 1.8s
- **Audit ID**: `first-contentful-paint`

### Largest Contentful Paint (LCP)

- **Measures**: Time until the largest content element (image, video, text block) is visible
- **Good**: < 2.5s
- **Audit ID**: `largest-contentful-paint`

### Total Blocking Time (TBT)

- **Measures**: Sum of all time periods where main thread was blocked > 50ms, between FCP and Time to Interactive
- **Good**: < 200ms
- **Audit ID**: `total-blocking-time`

### Cumulative Layout Shift (CLS)

- **Measures**: Sum of unexpected layout shift scores during the page's lifespan
- **Good**: < 0.1
- **Audit ID**: `cumulative-layout-shift`

### Speed Index (SI)

- **Measures**: How quickly contents of the page are visually populated
- **Good**: < 3.4s
- **Audit ID**: `speed-index`

---

## SEO audits checklist

| Audit | Description |
|-------|-------------|
| `meta-description` | Page has a `<meta name="description">` |
| `link-text` | Links have descriptive text |
| `hreflang` | Valid `hreflang` attributes |
| `canonical` | Valid `rel=canonical` |
| `http-status-code` | Successful HTTP status code |
| `invalid-robots-txt` | Valid `robots.txt` |
| `plugins` | No deprecated plugins (Flash, etc.) |
| `tap-targets` | Tap targets appropriately sized |
| `structured-data` | Valid structured data |
| `viewport` | Has a viewport meta tag |
| `crawlable-anchors` | Links are crawlable |
| `is-crawlable` | Page not blocked by robots.txt |
| `font-size` | Font size is legible |

---

## Accessibility audits overview

Lighthouse uses axe-core for automated accessibility testing. Key audit areas:

- **Color contrast**: Text has sufficient contrast ratio
- **ARIA**: Proper use of ARIA roles, attributes, and states
- **Forms**: Labels associated with inputs
- **Images**: Alt text on images
- **Navigation**: Logical heading order, skip links
- **Focus**: Focus indicators and keyboard navigation
- **Tables**: Proper table markup
- **Language**: `lang` attribute on `<html>`

---

## Best practices audits overview

| Area | Examples |
|------|---------|
| Security | HTTPS, no mixed content, CSP |
| Browser compatibility | No deprecated APIs, no `document.write` |
| Console | No browser errors logged |
| Images | Correct aspect ratio, proper resolution |
| General | No `unload` event listeners, proper charset |

---

## Throttling presets

### Mobile (default)

- 4× CPU slowdown
- Simulated slow 4G (150ms RTT, 1.6 Mbps down, 0.7 Mbps up)
- Mobile viewport (412×823, 1.75 DPR)

### Desktop (--preset=desktop)

- No CPU slowdown
- No network throttling
- Desktop viewport
- Desktop scoring curves (separate from mobile)

---

## Reference configs

Lighthouse maintains several built-in config files:

| Config | Purpose |
|--------|---------|
| `core/config/default-config.js` | Full default config |
| `core/config/lr-desktop-config.js` | PageSpeed Insights desktop |
| `core/config/lr-mobile-config.js` | PageSpeed Insights mobile |
| `core/config/perf-config.js` | Performance-only |

Browse them at: https://github.com/GoogleChrome/lighthouse/tree/main/core/config
