# Microsoft Clarity API — Full Reference

Official docs: https://learn.microsoft.com/en-us/clarity/setup-and-installation/clarity-api  
Data Export API: https://learn.microsoft.com/en-us/clarity/setup-and-installation/clarity-data-export-api  
Open source: https://github.com/microsoft/clarity

---

## Table of contents

1. [Client-side JavaScript API](#client-side-javascript-api)
   - [Cookie consent v2](#cookie-consent-v2)
   - [Cookie consent v1 (deprecated)](#cookie-consent-v1-deprecated)
   - [Identify API](#identify-api)
   - [Custom tags](#custom-tags)
   - [Custom events](#custom-events)
   - [Upgrade session](#upgrade-session)
   - [Metadata callback](#metadata-callback)
2. [HTML data attribute API](#html-data-attribute-api)
3. [Data Export REST API](#data-export-rest-api)
4. [Smart events (no-code)](#smart-events-no-code)
5. [Data collection reference](#data-collection-reference)
6. [Consent management platforms](#consent-management-platforms)

---

## Client-side JavaScript API

All methods use the global `window.clarity()` function injected by the tracking script.

### Cookie consent v2

**Purpose**: Signal user consent status for GDPR/EEA compliance.  
**Docs**: https://learn.microsoft.com/en-us/clarity/setup-and-installation/clarity-consent-api-v2

```javascript
window.clarity('consentv2', {
  ad_Storage: "granted" | "denied",
  analytics_Storage: "granted" | "denied"
});
```

| Parameter | Type | Required | Values |
|-----------|------|----------|--------|
| `ad_Storage` | string | Yes | `"granted"` or `"denied"` |
| `analytics_Storage` | string | Yes | `"granted"` or `"denied"` |

**Behavior**:
- When consent is **granted**: Clarity sets first-party and third-party cookies, enables multi-page session tracking.
- When consent is **denied**: Clarity operates in no-consent mode (unique ID per page view, no cookies, limited tracking).
- When a user **revokes** consent after granting it: Clarity deletes existing cookies, ends the session, restarts in no-consent mode.

**Enabling Consent Mode**: Go to **Settings → Setup** and turn OFF cookies. This forces Clarity to wait for a consent signal before setting cookies. Consent mode is enabled by default for EEA/UK/CH users starting October 31, 2025.

**Erase cookies** (works with both v1 and v2):

```javascript
window.clarity('consent', false);
```

---

### Cookie consent v1 (deprecated)

**Status**: Supported but planned for deprecation. Use v2 instead.  
**Docs**: https://learn.microsoft.com/en-us/clarity/setup-and-installation/clarity-consent-api-v1

```javascript
// Grant consent
window.clarity('consent');

// Erase cookies and stop tracking
window.clarity('consent', false);
```

When using v1 `consent`, the same granted/denied state applies to both `ad_storage` and `analytics_storage`.

---

### Identify API

**Purpose**: Link sessions across browsers and devices using your own user identifiers.  
**Docs**: https://learn.microsoft.com/en-us/clarity/setup-and-installation/identify-api

```javascript
window.clarity("identify", customId, customSessionId?, customPageId?, friendlyName?)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `customId` | string | Yes | Your internal user ID (email, DB ID, etc.) |
| `customSessionId` | string | No | Your own session identifier |
| `customPageId` | string | No | Your own page identifier |
| `friendlyName` | string | No | Display name shown in dashboard UI instead of hash |

**Returns**: `Promise<{ id: string, session: string, page: string, userHint: string }>`

**Privacy**: The `customId` is hashed on the client before being sent to Clarity servers. Clarity never stores the raw value. When filtering by custom user ID in the dashboard, Clarity hashes the search input and matches against stored hashes.

**Best practice**: Call on every page load for consistent cross-page tracking.

```javascript
// With friendly name — dashboard shows "Alice" instead of hash
window.clarity("identify", "alice@example.com", "session-abc", "home-page", "Alice");

// Without friendly name — dashboard shows truncated hash like "Al******************"
window.clarity("identify", "alice@example.com", "session-abc", "home-page");
```

**Filtering**: Use **Filters → Custom filters → Custom user ID** in the Clarity dashboard.

---

### Custom tags

**Purpose**: Apply arbitrary key-value metadata to sessions for filtering.  
**Docs**: https://learn.microsoft.com/en-us/clarity/filters/custom-tags

```javascript
window.clarity("set", key, value)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `key` | string | Yes | Tag name (≤ 255 characters) |
| `value` | string or string[] | Yes | Tag value(s) (≤ 255 characters each) |

**Limits**:
- No limit on total number of tags across sessions.
- Max 128 tags per single page (extras are ignored).
- Tags appear in **Filters → Custom tags** within 30 min to 2 hours.

```javascript
window.clarity("set", "experiment", "variant-a");
window.clarity("set", "userType", "premium");

// Array values — equivalent to calling set twice
window.clarity("set", "features", ["dark-mode", "beta-nav"]);
```

**Google Tag Manager**: You can also fire `clarity("set", ...)` via GTM JavaScript triggers.

---

### Custom events

**Purpose**: Fire named events that appear as Smart Events in dashboard, filters, and recording timelines.  
**Docs**: https://learn.microsoft.com/en-us/clarity/setup-and-installation/clarity-api#add-custom-events

```javascript
window.clarity("event", eventName)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `eventName` | string | Yes | Name of the event to log |

- Can be called multiple times per page.
- Each call logs an individual event.
- Events appear in **Filters**, **Dashboard**, **Settings → Smart Events**, and **Recordings**.

```javascript
window.clarity("event", "newsletterSignup");
window.clarity("event", "addToCart");
window.clarity("event", "checkoutComplete");
```

---

### Upgrade session

**Purpose**: Prioritize specific sessions for recording when traffic exceeds the 100,000 daily limit.  
**Docs**: https://learn.microsoft.com/en-us/clarity/setup-and-installation/clarity-api

```javascript
window.clarity("upgrade", reason)
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `reason` | string | Yes | Why this session should be prioritized |

```javascript
window.clarity("upgrade", "error page viewed");
window.clarity("upgrade", "high-value checkout");
```

When the daily recording limit is reached, Clarity samples recordings. Upgraded sessions bypass sampling.

---

### Metadata callback

**Purpose**: Inspect current session metadata and consent status programmatically.

```javascript
clarity('metadata', (data, upgrade, consent) => {
  console.log('consentStatus:', consent);
  // consent = { analytics_storage: "GRANTED"|"DENIED", ad_storage: "GRANTED"|"DENIED" }
}, false, true, true);
```

Useful for verifying consent mode is working correctly.

---

## HTML data attribute API

Declarative content masking via HTML attributes. Masked content is never uploaded to Clarity.

### Mask content

```html
<div data-clarity-mask="true">
  <!-- Everything inside is masked in recordings and heatmaps -->
  <input type="text" name="credit-card">
</div>
```

### Unmask content

```html
<article data-clarity-unmask="true">
  <!-- This content is explicitly captured even if a parent is masked -->
  <p>Public review text</p>
</article>
```

**Important**:
- Setting `data-clarity-mask` to `false` does **not** unmask content. Use `data-clarity-unmask="true"` instead.
- Setting `data-clarity-unmask` to `false` does **not** mask content. Use `data-clarity-mask="true"` instead.
- By default, Clarity auto-masks all input box content, numbers, and email addresses.
- You can also configure masking via the Clarity website UI without code changes.

---

## Data Export REST API

Server-side endpoint to download dashboard metrics as JSON.

**Docs**: https://learn.microsoft.com/en-us/clarity/setup-and-installation/clarity-data-export-api

### Authentication

JWT token generated by project admin:

1. **Settings → Data Export → Generate new API token**
2. Token name: 4–32 chars, alphanumeric + `-`, `_`, `.` only, no spaces, unique per project.
3. Include in every request: `Authorization: Bearer <TOKEN>`

### Endpoint

```
GET https://www.clarity.ms/export-data/api/v1/project-live-insights
```

### Query parameters

| Parameter | Required | Type | Values |
|-----------|----------|------|--------|
| `numOfDays` | Yes | int | `1`, `2`, or `3` (last 24/48/72 hours) |
| `dimension1` | No | string | Any dimension name |
| `dimension2` | No | string | Any dimension name |
| `dimension3` | No | string | Any dimension name |

### Available dimensions

- Browser
- Device
- Country/Region
- OS
- Source
- Medium
- Campaign
- Channel
- URL

### Metrics returned

- Traffic (totalSessionCount, totalBotSessionCount, distantUserCount, PagesPerSessionPercentage)
- Scroll Depth
- Engagement Time
- Popular Pages
- Browser
- Device
- OS
- Country/Region
- Page Title
- Referrer URL
- Dead Click Count
- Excessive Scroll
- Rage Click Count
- Quickback Click
- Script Error Count
- Error Click Count

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
      },
      {
        "totalSessionCount": "9554",
        "totalBotSessionCount": "8369",
        "distantUserCount": "189733",
        "PagesPerSessionPercentage": 1.0931,
        "OS": "Other"
      }
    ]
  }
]
```

### Error codes

| HTTP Code | Response | Cause |
|-----------|----------|-------|
| 401 | Unauthorized | Missing, invalid, or expired token |
| 403 | Forbidden | Token lacks required permissions |
| 400 | Bad Request | Invalid parameters |
| 429 | Too Many Requests | Exceeded 10 requests/day quota |

### Rate limits and constraints

- **10 requests per project per day**
- Data lookback: last 1–3 days only
- Max 3 dimensions per request
- Response capped at 1,000 rows, no pagination
- Results returned in UTC timezone

---

## Smart events (no-code)

Smart events combine click data, page views, and session signals to surface high-level user actions (Purchase, Add to Cart, Login, etc.). They can be created entirely code-free via **Settings → Smart Events → New event**.

Types:
- **Auto events**: Clarity automatically detects actions (9 built-in types: Purchase, Add to Cart, Begin Checkout, Contact Us, Submit Form, Request Quote, Sign Up, Login, Download)
- **Button clicks**: Track specific UI element clicks
- **API events**: Events fired via `window.clarity("event", ...)` 
- **Page visits**: Track visits to specific URLs

Limits: Max 20 custom smart events per project. Only project admins can create/edit.

---

## Data collection reference

Clarity collects three categories of data per session:

| Field | Name | Contents |
|-------|------|----------|
| `e` | Envelope | Metadata: version, sequence, timestamps, project/user/session IDs, upload type |
| `a` | Analytics | Interaction events (click, scroll, mouse move, resize, input), diagnostic events (script/image errors, performance), page events (dimensions, visibility), custom events |
| `p` | Playback | DOM structure and mutations for session replay (node positions, attributes, masked content, dimensions) |

Data is sent via POST to `https://www.clarity.ms/collect`.

---

## Consent management platforms

Clarity integrates with CMPs that automatically pass consent signals:

- **CookieYes** — fully supported, automatic consent signal passing
- Additional CMP integrations are in development

For unsupported CMPs or custom consent banners, use the [Consent v2 API](#cookie-consent-v2).
