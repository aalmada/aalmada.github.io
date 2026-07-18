---
name: lighthouse
description: Run Google Lighthouse audits to measure and improve web page quality — performance, accessibility, SEO, and best practices. Use this skill whenever the user mentions Lighthouse, page speed, performance audit, web vitals, Core Web Vitals, LCP, FCP, CLS, TBT, Speed Index, accessibility audit, SEO audit, PageSpeed Insights, or wants to measure, benchmark, or optimize website quality — even if they just say "check my site's performance" or "run a performance test".
---

# Google Lighthouse

Lighthouse is an open-source tool for auditing web page quality. It runs a suite of audits and produces scored reports across five categories: Performance, Accessibility, Best Practices, SEO, and Agentic Browsing. This skill covers the CLI, Node module, configuration, scoring, and CI integration.

## When to use

- Running performance, accessibility, SEO, or best-practices audits on a URL
- Interpreting Lighthouse scores and metrics
- Automating audits in CI/CD pipelines
- Configuring custom audit runs (specific categories, throttling, etc.)
- Understanding Core Web Vitals and how they affect scoring
- Generating reports in HTML, JSON, or CSV formats
- Diagnosing and fixing audit failures

## Audit categories

| Category             | What it measures                                                     |
| -------------------- | -------------------------------------------------------------------- |
| **Performance**      | Loading speed via Core Web Vitals and related metrics                |
| **Accessibility**    | Whether the page is usable by people with disabilities               |
| **Best Practices**   | General web development best practices (HTTPS, console errors, etc.) |
| **SEO**              | Whether the page is optimized for search engine indexing             |
| **Agentic Browsing** | Whether the page is compatible with AI agents (new category)         |

---

## Running Lighthouse

### CLI (recommended for automation)

Install globally:

```bash
npm install -g lighthouse
```

Basic audit:

```bash
lighthouse https://example.com
```

Common flags:

```bash
# Output JSON instead of HTML
lighthouse https://example.com --output json --output-path report.json

# Multiple output formats
lighthouse https://example.com --output html --output json

# Run only specific categories
lighthouse https://example.com --only-categories=performance,seo

# Desktop emulation (default is mobile)
lighthouse https://example.com --preset=desktop

# Custom Chrome flags (e.g., headless)
lighthouse https://example.com --chrome-flags="--headless"

# Specify Chrome port (for pre-launched Chrome)
lighthouse https://example.com --port=9222

# Quiet mode (less output)
lighthouse https://example.com --quiet

# View all options
lighthouse --help
```

### Node module (programmatic)

Install as dependency:

```bash
npm install lighthouse chrome-launcher
```

Run programmatically:

```javascript
import fs from "fs";
import lighthouse from "lighthouse";
import * as chromeLauncher from "chrome-launcher";

const chrome = await chromeLauncher.launch({ chromeFlags: ["--headless"] });
const options = {
  logLevel: "info",
  output: "html",
  onlyCategories: ["performance"],
  port: chrome.port,
};
const result = await lighthouse("https://example.com", options);

// HTML report as string
const reportHtml = result.report;
fs.writeFileSync("report.html", reportHtml);

// Lighthouse Result object
console.log("URL:", result.lhr.finalDisplayedUrl);
console.log("Performance:", result.lhr.categories.performance.score * 100);

await chrome.kill();
```

Performance-only run:

```javascript
const result = await lighthouse(url, { onlyCategories: ["performance"] });
```

### Chrome DevTools

1. Open Chrome DevTools (F12 or Cmd+Option+I)
2. Click the **Lighthouse** tab
3. Select categories and device type
4. Click **Analyze page load**

### PageSpeed Insights (web UI)

Go to https://pagespeed.web.dev/ and enter a URL. Uses Lighthouse under the hood with real-world CrUX data.

---

## Performance scoring (Lighthouse 10)

The performance score is a weighted average of five metrics:

| Metric                             | Weight | What it measures                                           |
| ---------------------------------- | ------ | ---------------------------------------------------------- |
| **Total Blocking Time (TBT)**      | 30%    | Sum of time chunks where main thread was blocked > 50ms    |
| **Largest Contentful Paint (LCP)** | 25%    | When the largest content element becomes visible           |
| **Cumulative Layout Shift (CLS)**  | 25%    | Visual stability — how much the layout shifts unexpectedly |
| **First Contentful Paint (FCP)**   | 10%    | When the first content pixel is painted                    |
| **Speed Index (SI)**               | 10%    | How quickly the page contents are visually populated       |

### Score color coding

| Score range | Color  | Meaning           |
| ----------- | ------ | ----------------- |
| 90–100      | Green  | Good              |
| 50–89       | Orange | Needs improvement |
| 0–49        | Red    | Poor              |

### How metric scores are calculated

Each raw metric value (in milliseconds or unitless) is mapped to a 0–100 score using a log-normal distribution derived from real website data in the HTTP Archive. The 25th percentile maps to a score of 50, and the 8th percentile maps to 90.

Use the [Lighthouse Scoring Calculator](https://googlechrome.github.io/lighthouse/scorecalc/) to explore thresholds.

---

## Configuration

Custom configs let you control which audits run, scoring weights, and throttling. Pass a config as the third argument to `lighthouse()` or via `--config-path` on the CLI.

### Extending the default config

```javascript
// custom-config.js
export default {
  extends: "lighthouse:default",
  settings: {
    onlyCategories: ["performance"],
    // or limit to specific audits:
    // onlyAudits: ['speed-index', 'interactive'],
    // or skip specific audits:
    // skipAudits: ['uses-http2'],
  },
};
```

```bash
lighthouse https://example.com --config-path=custom-config.js
```

### Config properties

| Property                  | Type                                  | Description                                                    |
| ------------------------- | ------------------------------------- | -------------------------------------------------------------- |
| `extends`                 | `"lighthouse:default"` or `undefined` | Inherit default artifacts, audits, groups, and categories      |
| `settings`                | Object                                | Control categories, audits, throttling                         |
| `settings.onlyCategories` | string[]                              | Run only these categories                                      |
| `settings.onlyAudits`     | string[]                              | Run only these audits (additive with onlyCategories)           |
| `settings.skipAudits`     | string[]                              | Skip these audits (takes priority over onlyCategories)         |
| `artifacts`               | Object[]                              | Gatherers to run (`{id, gatherer}`)                            |
| `audits`                  | string[]                              | Audit modules to include                                       |
| `categories`              | Object                                | Define categories with `title`, `description`, and `auditRefs` |
| `groups`                  | Object                                | Visual grouping of audits in the report                        |
| `plugins`                 | string[]                              | Lighthouse plugins to include                                  |

### Custom categories example

```javascript
export default {
  extends: "lighthouse:default",
  categories: {
    performance: {
      title: "Performance Metrics",
      description: "Key performance indicators.",
      auditRefs: [
        { id: "first-contentful-paint", weight: 3, group: "metrics" },
        { id: "interactive", weight: 5, group: "metrics" },
      ],
    },
  },
};
```

---

## Lighthouse CI

[Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci) prevents regressions by running Lighthouse in CI pipelines and asserting score budgets.

Install:

```bash
npm install -g @lhci/cli
```

Basic usage:

```bash
lhci autorun --collect.url=https://example.com --assert.preset=lighthouse:recommended
```

---

## Key CLI flags reference

| Flag                                 | Description                                        |
| ------------------------------------ | -------------------------------------------------- |
| `--output`                           | Report format: `html`, `json`, `csv`               |
| `--output-path`                      | File path for the report                           |
| `--only-categories`                  | Comma-separated categories to run                  |
| `--preset`                           | `desktop` or `perf` (default is mobile simulation) |
| `--chrome-flags`                     | Extra Chrome flags (e.g., `--headless`)            |
| `--port`                             | Chrome debugging port                              |
| `--config-path`                      | Path to custom config file                         |
| `--quiet`                            | Suppress log output                                |
| `--view`                             | Open report in browser after run                   |
| `--screenEmulation.disabled`         | Disable screen emulation                           |
| `--throttling-method`                | `simulate` (default), `devtools`, or `provided`    |
| `--throttling.cpuSlowdownMultiplier` | CPU throttling factor (default: 4 for mobile)      |

---

## Node module — key differences from CLI

When using `lighthouse()` programmatically, some CLI flags behave differently:

| Flag              | Behavior in Node module                                |
| ----------------- | ------------------------------------------------------ |
| `port`            | Only specifies port; Chrome is not launched for you    |
| `chromeFlags`     | Ignored — launch Chrome yourself via `chrome-launcher` |
| `outputPath`      | Ignored — report is returned as string in `.report`    |
| `saveAssets`      | Ignored — artifacts in `.artifacts`                    |
| `view`            | Ignored — use the `open` npm module if needed          |
| `configPath`      | Ignored — pass config as 3rd argument                  |
| `verbose`/`quiet` | Ignored — use `logLevel: 'info'` or `'error'`          |

---

## Lighthouse Result (LHR) object

The `.lhr` property of the result contains the full audit data:

```javascript
result.lhr.categories.performance.score; // 0–1 (multiply by 100)
result.lhr.categories.accessibility.score;
result.lhr.categories.seo.score;
result.lhr.categories["best-practices"].score;
result.lhr.audits["first-contentful-paint"].numericValue; // milliseconds
result.lhr.audits["largest-contentful-paint"].numericValue;
result.lhr.audits["cumulative-layout-shift"].numericValue;
result.lhr.finalDisplayedUrl;
result.lhr.fetchTime; // ISO timestamp
```

---

## Testing special scenarios

### Authenticated pages

1. Run `chrome-debug` (installed with global Lighthouse)
2. Navigate to the site and log in
3. In another terminal: `lighthouse http://mysite.com --port <port-number>`

### Sites with untrusted certificates

Add the certificate to your local trust store (recommended), or use:

```bash
lighthouse https://localhost --chrome-flags="--ignore-certificate-errors"
```

### Mobile device testing

```bash
adb forward tcp:9222 localabstract:chrome_devtools_remote
lighthouse --port=9222 --screenEmulation.disabled --throttling.cpuSlowdownMultiplier=1 --throttling-method=provided https://example.com
```

---

## Sharing reports

- **JSON**: `lighthouse --output json --output-path report.json`
- **Lighthouse Viewer**: Upload JSON at https://googlechrome.github.io/lighthouse/viewer/
- **GitHub Gist**: Save as `*.lighthouse.report.json`, view at `https://googlechrome.github.io/lighthouse/viewer/?gist=<GIST_ID>`

## Reference

For detailed configuration schema and examples, see `references/configuration.md`.
