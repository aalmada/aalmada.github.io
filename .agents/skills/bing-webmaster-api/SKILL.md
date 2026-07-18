---
name: bing-webmaster-api
description: Interact with the Bing Webmaster Tools API to submit URLs, manage sitemaps, monitor crawl health, retrieve traffic and ranking stats, inspect indexed pages, and research keywords. Use this skill whenever the user mentions Bing Webmaster, Bing indexing, submitting URLs to Bing, Bing crawl stats, Bing search traffic, Bing sitemaps, Bing SEO data, or wants to programmatically manage their site on Bing — even if they just say "submit to Bing" or "check Bing indexing status".
---

# Bing Webmaster API

Programmatically manage a site's presence on Bing Search: submit URLs and content for indexing, manage sitemaps, monitor crawl health, retrieve traffic/ranking statistics, and research keywords.

## When to use

- Submitting new or updated URLs to Bing for indexing
- Submitting page content directly to Bing (Content Submission API)
- Managing sitemaps (submit, list, remove feeds)
- Checking crawl statistics and crawl issues
- Retrieving search traffic data (impressions, clicks, position)
- Analyzing top queries and top pages
- Researching keyword impressions and related keywords
- Inspecting index status for specific URLs
- Reviewing inbound link counts
- Managing URL blocking or page preview blocking
- Configuring crawl settings
- Checking submission quotas

## Authentication

The API supports two authentication methods. Never hardcode or log API keys or tokens.

### API Key (simplest)

Generate at: Bing Webmaster Tools → Settings → API Access → Generate API Key.
Pass as query parameter `apikey` on every request.

### OAuth 2.0 (recommended for third-party apps)

Uses authorization code flow with these endpoints:

| Step      | Endpoint                                              |
| --------- | ----------------------------------------------------- |
| Authorize | `GET https://www.bing.com/webmasters/oauth/authorize` |
| Token     | `POST https://www.bing.com/webmasters/oauth/token`    |
| Refresh   | `POST https://www.bing.com/webmasters/token`          |

Scopes: `webmaster.read` (read-only), `webmaster.manage` (read + write).

When using OAuth, pass the access token via `Authorization: Bearer <token>` header instead of the `apikey` query parameter.

## Base URL and protocols

The API supports JSON, POX (XML), and SOAP protocols. Prefer JSON.

| Protocol | GET format                                                                      | POST format                                                         |
| -------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| JSON     | `https://ssl.bing.com/webmaster/api.svc/json/{METHOD}?apikey={KEY}&param=value` | `https://ssl.bing.com/webmaster/api.svc/json/{METHOD}?apikey={KEY}` |
| POX      | `https://ssl.bing.com/webmaster/api.svc/pox/{METHOD}?apikey={KEY}&param=value`  | `https://ssl.bing.com/webmaster/api.svc/pox/{METHOD}?apikey={KEY}`  |

POST requests use `Content-Type: application/json; charset=utf-8` with a JSON body.

## Error handling

On error, the API returns HTTP 400 with a JSON body:

```json
{ "ErrorCode": 3, "Message": "InvalidApiKey" }
```

Common error codes:

- `1` — Internal error
- `2` — Invalid parameter
- `3` — Invalid API key
- `4` — Not authorized
- `5` — Quota exceeded

## API method groups

The API has ~50 methods. Read `references/api-reference.md` for the full method catalog with parameters, request/response examples, and remarks. Below is a summary organized by task.

### URL submission

| Method                      | HTTP | Description                                                      |
| --------------------------- | ---- | ---------------------------------------------------------------- |
| `SubmitUrl`                 | POST | Submit a single URL for indexing                                 |
| `SubmitUrlBatch`            | POST | Submit up to 500 URLs at once                                    |
| `SubmitContent`             | POST | Submit URL with full page content (base64-encoded HTTP response) |
| `GetUrlSubmissionQuota`     | GET  | Check daily/monthly URL submission quota                         |
| `GetContentSubmissionQuota` | GET  | Check daily/monthly content submission quota                     |

### Sitemap / feed management

| Method           | HTTP | Description                         |
| ---------------- | ---- | ----------------------------------- |
| `SubmitFeed`     | POST | Submit a sitemap, RSS, or Atom feed |
| `GetFeeds`       | GET  | List all submitted feeds for a site |
| `GetFeedDetails` | GET  | Get details for a specific feed     |
| `RemoveFeed`     | POST | Remove a submitted feed             |

### Traffic and ranking

| Method                    | HTTP | Description                                                     |
| ------------------------- | ---- | --------------------------------------------------------------- |
| `GetRankAndTrafficStats`  | GET  | Daily impressions and clicks (updated daily)                    |
| `GetQueryStats`           | GET  | Top queries with clicks, impressions, position (updated weekly) |
| `GetPageStats`            | GET  | Top pages with clicks, impressions, position (updated weekly)   |
| `GetQueryTrafficStats`    | GET  | Traffic stats for a specific query                              |
| `GetPageQueryStats`       | GET  | Traffic stats for a specific page                               |
| `GetQueryPageStats`       | GET  | Pages ranked for a specific query                               |
| `GetQueryPageDetailStats` | GET  | Detailed stats for a query+page combination                     |

### Crawl monitoring

| Method              | HTTP | Description                                    |
| ------------------- | ---- | ---------------------------------------------- |
| `GetCrawlStats`     | GET  | Crawl statistics for the last 6 months         |
| `GetCrawlIssues`    | GET  | URLs with crawl issues (malware, errors, etc.) |
| `GetCrawlSettings`  | GET  | Current crawl rate settings                    |
| `SaveCrawlSettings` | POST | Update crawl rate settings                     |

### Index inspection

| Method                      | HTTP | Description                                |
| --------------------------- | ---- | ------------------------------------------ |
| `GetUrlInfo`                | GET  | Index details for a single page            |
| `GetUrlTrafficInfo`         | GET  | Traffic details for a single page          |
| `GetChildrenUrlInfo`        | GET  | Index details for URLs under a directory   |
| `GetChildrenUrlTrafficInfo` | GET  | Traffic details for URLs under a directory |
| `FetchUrl`                  | POST | Request Bing to fetch a specific URL       |
| `GetFetchedUrls`            | GET  | List of URLs fetched on demand             |
| `GetFetchedUrlDetails`      | GET  | Details of a fetched URL                   |

### Keyword research

| Method               | HTTP | Description                                            |
| -------------------- | ---- | ------------------------------------------------------ |
| `GetKeyword`         | GET  | Impressions for a keyword in a country/language/period |
| `GetKeywordStats`    | GET  | Historical statistics for a keyword                    |
| `GetRelatedKeywords` | GET  | Related keyword impressions                            |

### Link analysis

| Method          | HTTP | Description                          |
| --------------- | ---- | ------------------------------------ |
| `GetLinkCounts` | GET  | Pages with inbound links (paginated) |
| `GetUrlLinks`   | GET  | Inbound links for a specific URL     |

### Site management

| Method         | HTTP | Description               |
| -------------- | ---- | ------------------------- |
| `GetUserSites` | GET  | List all registered sites |
| `AddSite`      | POST | Register a new site       |
| `RemoveSite`   | POST | Remove a registered site  |
| `VerifySite`   | POST | Attempt site verification |

### URL blocking and page preview

| Method                       | HTTP | Description                         |
| ---------------------------- | ---- | ----------------------------------- |
| `AddBlockedUrl`              | POST | Block a page/directory from results |
| `GetBlockedUrls`             | GET  | List blocked URLs                   |
| `RemoveBlockedUrl`           | POST | Unblock a URL                       |
| `AddPagePreviewBlock`        | POST | Block page preview/snapshot         |
| `GetActivePagePreviewBlocks` | GET  | List active preview blocks          |
| `RemovePagePreviewBlock`     | POST | Remove a preview block              |

## Quick-start examples

### Submit a single URL (curl + API key)

```bash
curl -X POST "https://ssl.bing.com/webmaster/api.svc/json/SubmitUrl?apikey=YOUR_API_KEY" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"siteUrl":"https://example.com","url":"https://example.com/new-post"}'
```

### Submit a batch of URLs

```bash
curl -X POST "https://ssl.bing.com/webmaster/api.svc/json/SubmitUrlBatch?apikey=YOUR_API_KEY" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{
    "siteUrl":"https://example.com",
    "urlList":["https://example.com/post-1","https://example.com/post-2"]
  }'
```

### Check URL submission quota

```bash
curl "https://ssl.bing.com/webmaster/api.svc/json/GetUrlSubmissionQuota?siteUrl=https://example.com&apikey=YOUR_API_KEY"
```

Response:

```json
{
  "d": {
    "__type": "UrlSubmissionQuota:#Microsoft.Bing.Webmaster.Api",
    "DailyQuota": 5,
    "MonthlyQuota": 24
  }
}
```

### Get traffic stats

```bash
curl "https://ssl.bing.com/webmaster/api.svc/json/GetRankAndTrafficStats?siteUrl=https://example.com&apikey=YOUR_API_KEY"
```

### Submit a sitemap

```bash
curl -X POST "https://ssl.bing.com/webmaster/api.svc/json/SubmitFeed?apikey=YOUR_API_KEY" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"siteUrl":"https://example.com","feedUrl":"https://example.com/sitemap.xml"}'
```

## Important constraints

- **URL submission quota**: Call `GetUrlSubmissionQuota` before submitting. Daily and monthly limits apply.
- **Batch limit**: `SubmitUrlBatch` accepts up to 500 URLs per call (within remaining quota).
- **Content submission**: Up to 10 MB uncompressed payload per request. Supports gzip. Call `GetContentSubmissionQuota` to check limits.
- **Feed formats**: Sitemap XML, RSS 2.0, Atom 0.3, Atom 1.0, and plain text files.
- **Data freshness**: Traffic/rank stats update daily; query/page stats update weekly; crawl stats update daily.
- **Crawl issue lag**: Fixed issues may take a few days to disappear from `GetCrawlIssues`.
- **Site must be verified**: Most API methods require the site to be verified in Bing Webmaster Tools first.

## Security reminders

- Never log, echo, or hardcode API keys or OAuth tokens.
- Store credentials in environment variables or secret managers.
- Use `webmaster.read` scope when write access is not needed.
- Validate and sanitize any user-provided URLs before passing to the API.

## Reference

For the full method catalog with parameters, example requests, and example responses, read:
`references/api-reference.md`
