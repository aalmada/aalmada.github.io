---
name: clarity-api
description: Integrate Microsoft Clarity analytics into websites — add tracking, manage cookie consent, tag sessions, fire custom events, identify users across devices, mask sensitive content, prioritize recordings, and export dashboard data via the REST API. Use this skill whenever the user mentions Clarity, Clarity tracking, Clarity heatmaps, Clarity session recordings, Clarity consent, Clarity custom tags, Clarity events, Clarity data export, or wants to add behavioral analytics to a site — even if they just say "add analytics" or "track user behavior".
---

# Microsoft Clarity API

Microsoft Clarity is a free behavioral analytics tool that provides session recordings, heatmaps, and insights about how users interact with a website. This skill covers the two API surfaces:

1. **Client-side API** — JavaScript calls and HTML attributes embedded in the webpage to control tracking behavior, consent, custom tags, events, user identification, content masking, and session prioritization.
2. **Data Export REST API** — A server-side endpoint to programmatically download dashboard metrics.

## When to use

- Installing or configuring Clarity tracking on a site
- Managing cookie consent (GDPR/EEA compliance)
- Identifying users across devices and sessions
- Adding custom tags to filter sessions in the Clarity dashboard
- Firing custom events for smart event tracking
- Masking or unmasking sensitive content
- Prioritizing specific sessions for recording when traffic exceeds daily limits
- Exporting dashboard data for analysis or integration

## Setup — installing the tracking code

Clarity requires a tracking code snippet in the `<head>` of every page. Each Clarity project has a unique project ID that serves as the API key — no separate key is needed.

### Manual installation

Copy the tracking code from **Settings → Setup** in your Clarity project and paste it into your site's `<head>`.

### NPM installation

```bash
npm install @microsoft/clarity
```

```javascript
import Clarity from "@microsoft/clarity";
Clarity.init("YOUR_PROJECT_ID");
```

### Verification

Check for POST requests to `https://www.clarity.ms/collect` in browser DevTools → Network tab.

---

## Client-side JavaScript API

All JavaScript APIs use the global `window.clarity()` function. Call them after the Clarity tracking script has loaded.

### Summary table

| Purpose                         | Syntax                                                                     | Required params |
| ------------------------------- | -------------------------------------------------------------------------- | --------------- |
| Cookie consent (v2)             | `window.clarity('consentv2', {ad_Storage, analytics_Storage})`             | Both            |
| Cookie consent (v1, deprecated) | `window.clarity('consent')`                                                | None            |
| Erase cookies                   | `window.clarity('consent', false)`                                         | None            |
| Identify user                   | `window.clarity('identify', customId, sessionId?, pageId?, friendlyName?)` | `customId`      |
| Custom tag                      | `window.clarity('set', key, value)`                                        | Both            |
| Custom event                    | `window.clarity('event', eventName)`                                       | `eventName`     |
| Upgrade session                 | `window.clarity('upgrade', reason)`                                        | `reason`        |

---

### Cookie consent

Starting October 31, 2025, Clarity enforces consent for users from the EEA, UK, and Switzerland. Without a consent signal, Clarity operates in no-consent mode (no cookies, unique ID per page view, no multi-page sessions).

#### Consent v2 (recommended)

```javascript
// User accepts all cookies
window.clarity("consentv2", {
  ad_Storage: "granted",
  analytics_Storage: "granted",
});

// User denies ad tracking but accepts analytics
window.clarity("consentv2", {
  ad_Storage: "denied",
  analytics_Storage: "granted",
});

// User denies all cookies
window.clarity("consentv2", {
  ad_Storage: "denied",
  analytics_Storage: "denied",
});
```

Typical integration with a cookie banner:

```javascript
window.addEventListener("consentGranted", () => {
  window.clarity("consentv2", {
    ad_Storage: "granted",
    analytics_Storage: "granted",
  });
});
```

#### Consent v1 (deprecated, still functional)

```javascript
window.clarity("consent"); // grant consent
window.clarity("consent", false); // erase cookies and stop tracking
```

#### Verify consent status

Run in browser console:

```javascript
clarity(
  "metadata",
  (d, upgrade, consent) => {
    console.log("consentStatus:", consent);
  },
  false,
  true,
  true,
);
```

Expected output when consent is denied:

```javascript
{ analytics_storage: "DENIED", ad_storage: "DENIED" }
```

---

### Identify API

Link sessions across browsers and devices by providing a custom user identifier. Clarity hashes the `custom-id` client-side before sending — the raw value never reaches Clarity servers.

```javascript
window.clarity(
  "identify",
  "custom-id",
  "custom-session-id",
  "custom-page-id",
  "friendly-name",
);
```

| Parameter           | Required | Description                                          |
| ------------------- | -------- | ---------------------------------------------------- |
| `custom-id`         | Yes      | Your internal user identifier (email, user ID, etc.) |
| `custom-session-id` | No       | Your own session identifier                          |
| `custom-page-id`    | No       | Your own page identifier                             |
| `friendly-name`     | No       | Display name shown in dashboard instead of hash      |

**Returns**: `Promise<{ id, session, page, userHint }>`

Call on every page load for consistent tracking:

```javascript
// Homepage
window.clarity(
  "identify",
  "user@example.com",
  "session-abc",
  "home-page",
  "Alice",
);

// Product page
window.clarity(
  "identify",
  "user@example.com",
  "session-abc",
  "product-page",
  "Alice",
);
```

Filter by custom user ID in: **Filters → Custom filters → Custom user ID**.

---

### Custom tags

Apply arbitrary key-value metadata to sessions. Tags appear in the Clarity dashboard under **Filters → Custom tags** (within 30 minutes to 2 hours).

```javascript
window.clarity("set", "key", "value");
```

- No limit on the number of tags.
- Value can be a string or array of strings.
- A single page can have up to 128 tags (extras are ignored).
- Key and value must each be ≤ 255 characters.

```javascript
window.clarity("set", "experiment", "variant-a");
window.clarity("set", "plan", ["free", "trial"]); // equivalent to two calls
```

---

### Custom events

Fire named events that appear as Smart Events in the dashboard, filters, and recordings timeline.

```javascript
window.clarity("event", "eventName");
```

Can be called multiple times per page. Each event is logged individually.

```javascript
window.clarity("event", "newsletterSignup");
window.clarity("event", "addToCart");
```

Events can also be created code-free via **Settings → Smart Events** in the Clarity dashboard.

---

### Upgrade (prioritize session recording)

Clarity records up to 100,000 sessions per project per day. Beyond that limit, it samples. Use `upgrade` to ensure specific sessions are always recorded.

```javascript
window.clarity("upgrade", "reason");
```

```javascript
window.clarity("upgrade", "checkout interaction");
window.clarity("upgrade", "error encountered");
```

---

## HTML data attribute API

Control content masking declaratively on HTML elements. Masked content is never uploaded to Clarity.

| Purpose        | Attribute                    | Effect                               |
| -------------- | ---------------------------- | ------------------------------------ |
| Mask content   | `data-clarity-mask="true"`   | Prevents content from being captured |
| Unmask content | `data-clarity-unmask="true"` | Ensures content is captured          |

Setting either to `false` has **no effect**. To toggle, use the opposite attribute.

```html
<!-- Mask a form -->
<form data-clarity-mask="true">
  <input type="text" name="ssn" />
</form>

<!-- Unmask a review section -->
<article data-clarity-unmask="true">
  <p>This review will be captured in recordings.</p>
</article>
```

By default, Clarity automatically masks input box content, numbers, and email addresses.

---

## Data Export REST API

A server-side API to download dashboard metrics programmatically. Useful for data pipelines, reporting dashboards, or integration with other analytics systems.

### Authentication

Requires a JWT token generated by a project admin:

1. Go to **Settings → Data Export → Generate new API token**.
2. Name the token (4–32 chars, alphanumeric + `-_. ` only, unique per project).
3. Copy and store securely.

Include in requests:

```
Authorization: Bearer <YOUR_TOKEN>
```

### Endpoint

```
GET https://www.clarity.ms/export-data/api/v1/project-live-insights
```

### Parameters

| Parameter    | Required | Values           | Description                                |
| ------------ | -------- | ---------------- | ------------------------------------------ |
| `numOfDays`  | Yes      | `1`, `2`, or `3` | Lookback period (last 24, 48, or 72 hours) |
| `dimension1` | No       | See list below   | First breakdown dimension                  |
| `dimension2` | No       | See list below   | Second breakdown dimension                 |
| `dimension3` | No       | See list below   | Third breakdown dimension                  |

**Available dimensions**: Browser, Device, Country/Region, OS, Source, Medium, Campaign, Channel, URL

**Metrics returned**: Traffic, Scroll Depth, Engagement Time, Popular Pages, Browser, Device, OS, Country/Region, Page Title, Referrer URL, Dead Click Count, Excessive Scroll, Rage Click Count, Quickback Click, Script Error Count, Error Click Count

### Example — curl

```bash
curl 'https://www.clarity.ms/export-data/api/v1/project-live-insights?numOfDays=1&dimension1=OS' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

### Example — Python

```python
import requests

response = requests.get(
    "https://www.clarity.ms/export-data/api/v1/project-live-insights",
    params={"numOfDays": "1", "dimension1": "OS"},
    headers={
        "Authorization": "Bearer YOUR_TOKEN",
        "Content-Type": "application/json"
    }
)
print(response.json())
```

### Sample response

```json
[
  {
    "metricName": "Traffic",
    "information": [
      {
        "totalSessionCount": "291942",
        "totalBotSessionCount": "31076",
        "distantUserCount": "212836",
        "PagesPerSessionPercentage": 2.2609,
        "OS": "Android"
      }
    ]
  }
]
```

### Error codes

| Code | Meaning           | Common cause                            |
| ---- | ----------------- | --------------------------------------- |
| 401  | Unauthorized      | Missing, invalid, or expired token      |
| 403  | Forbidden         | Token not authorized for this operation |
| 400  | Bad Request       | Invalid parameters                      |
| 429  | Too Many Requests | Exceeded daily quota                    |

### Limits

- **10 requests per project per day**
- Data limited to the last 1–3 days
- Maximum 3 dimensions per request
- Response capped at 1,000 rows (no pagination)

---

## Important constraints

- Clarity must **not** be used on sites targeting users under 18.
- Bot detection is enabled by default; bot sessions are excluded from analytics.
- Recordings are retained for 30 days; favorited recordings and a random sample are kept up to 9 months.
- Heatmap data is retained up to 9 months, limited to 100,000 page views per heatmap.
- Clarity cannot capture content inside `<canvas>` or third-party `<iframe>` elements.

## Security reminders

- Never log, echo, or hardcode Data Export API tokens.
- Store tokens in environment variables or secret managers.
- Promptly rotate tokens when a team member with access is removed.
- Custom IDs passed to `identify` are hashed client-side — but avoid passing raw PII in custom tags or event names.
- Use `data-clarity-mask` to prevent sensitive content from being captured.

## Reference

For deeper details on each API, see `references/api-reference.md`.
