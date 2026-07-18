# Bing Webmaster API — Full Method Reference

Base URL: `https://ssl.bing.com/webmaster/api.svc/json/`

All GET methods append parameters as query strings. All POST methods send a JSON body.  
Authentication: append `?apikey=API_KEY` to the URL, or use `Authorization: Bearer <token>` header with OAuth.

Official docs: https://learn.microsoft.com/en-us/bingwebmaster/  
API interface reference: https://learn.microsoft.com/en-us/dotnet/api/microsoft.bing.webmaster.api.interfaces.iwebmasterapi

---

## Table of contents

1. [Site management](#site-management)
2. [URL submission](#url-submission)
3. [Content submission](#content-submission)
4. [Sitemap / feed management](#sitemap--feed-management)
5. [Traffic and ranking statistics](#traffic-and-ranking-statistics)
6. [Crawl monitoring](#crawl-monitoring)
7. [Index inspection](#index-inspection)
8. [Keyword research](#keyword-research)
9. [Link analysis](#link-analysis)
10. [URL blocking](#url-blocking)
11. [Page preview blocking](#page-preview-blocking)
12. [Deep link management](#deep-link-management)
13. [URL normalization](#url-normalization)
14. [Country/region settings](#countryregion-settings)
15. [Site roles](#site-roles)
16. [Site moves](#site-moves)
17. [Connected pages](#connected-pages)

---

## Site management

### GetUserSites

List all registered sites for the authenticated user.

- **HTTP**: `GET /GetUserSites?apikey={KEY}`
- **Parameters**: none
- **Returns**: Array of `Site` objects

```json
// Response
{"d":[{
  "__type":"Site:#Microsoft.Bing.Webmaster.Api",
  "AuthenticationCode":"258CAD36B9EEE22F1CFDEB4C239D26BB",
  "DnsVerificationCode":"258cad36b9eee22f1cfdeb4c239d26bb.example.com",
  "IsVerified":false,
  "Url":"http://example.com"
}]}
```

### AddSite

Register a new site.

- **HTTP**: `POST /AddSite?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com"}`

### RemoveSite

Remove a registered site.

- **HTTP**: `POST /RemoveSite?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com"}`

### VerifySite

Attempt to verify ownership of a site.

- **HTTP**: `POST /VerifySite?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com"}`

---

## URL submission

### SubmitUrl

Submit a single URL for indexing.

- **HTTP**: `POST /SubmitUrl?apikey={KEY}`
- **Body**:

```json
{"siteUrl":"http://example.com", "url":"http://example.com/url1.html"}
```

- **Response**: `{"d":null}` (HTTP 200 on success)
- **Remarks**: Check `GetUrlSubmissionQuota` first. Quota limits apply.

### SubmitUrlBatch

Submit up to 500 URLs at once.

- **HTTP**: `POST /SubmitUrlBatch?apikey={KEY}`
- **Body**:

```json
{
  "siteUrl":"http://example.com",
  "urlList":["http://example.com/url1","http://example.com/url2"]
}
```

- **Response**: `{"d":null}` (HTTP 200 on success)
- **Remarks**: Max 500 URLs per call unless it exceeds remaining quota.

### GetUrlSubmissionQuota

Check daily and monthly URL submission quota.

- **HTTP**: `GET /GetUrlSubmissionQuota?siteUrl={SITE_URL}&apikey={KEY}`
- **Returns**: `UrlSubmissionQuota`

```json
{"d":{"__type":"UrlSubmissionQuota:#Microsoft.Bing.Webmaster.Api","DailyQuota":5,"MonthlyQuota":24}}
```

---

## Content submission

### SubmitContent

Submit a URL along with its full page content for immediate indexing.

- **HTTP**: `POST /SubmitContent?apikey={KEY}`
- **Parameters**:
  - `siteUrl` (string) — site root URL
  - `url` (string) — page URL to submit
  - `httpMessage` (string) — base64-encoded full HTTP response (status line + headers + body)
  - `structuredData` (string) — base64-encoded JSON-LD structured data (empty string if none)
  - `dynamicServing` (int) — `0`=none, `1`=PC/laptop, `2`=mobile, `3`=AMP, `4`=tablet, `5`=non-visual

```json
{
  "siteUrl":"http://example.com",
  "url":"http://example.com/url1.html",
  "httpMessage":"SFRUUC8xLjEgMjAwIE9L...(base64)...",
  "structuredData":"",
  "dynamicServing":"0"
}
```

- **Remarks**: Max 10 MB uncompressed per request. Supports gzip. Check `GetContentSubmissionQuota` first.
- The `httpMessage` must include the HTTP status line (e.g., `HTTP/1.1 200 OK`), headers ending with `\r\n`, an empty line (`\r\n`), and the body — all base64-encoded together.

### GetContentSubmissionQuota

Check daily and monthly content submission quota.

- **HTTP**: `GET /GetContentSubmissionQuota?siteUrl={SITE_URL}&apikey={KEY}`
- **Returns**: `ContentSubmissionQuota`

```json
{"d":{"__type":"ContentSubmissionQuota:#Microsoft.Bing.Webmaster.Api","DailyQuota":100,"MonthlyQuota":3000}}
```

---

## Sitemap / feed management

### SubmitFeed

Submit a sitemap or feed.

- **HTTP**: `POST /SubmitFeed?apikey={KEY}`
- **Body**:

```json
{"siteUrl":"http://example.com","feedUrl":"http://example.com/sitemap.xml"}
```

- **Supported formats**: Sitemap XML, RSS 2.0, Atom 0.3, Atom 1.0, text files.

### GetFeeds

List all top-level feeds for a site.

- **HTTP**: `GET /GetFeeds?siteUrl={SITE_URL}&apikey={KEY}`
- **Returns**: Array of `Feed` objects

```json
{"d":[{
  "__type":"Feed:#Microsoft.Bing.Webmaster.Api",
  "Compressed":false,
  "FileSize":1024,
  "LastCrawled":"/Date(1315781995040-0700)/",
  "Status":"Success",
  "Submitted":"/Date(1316213995040-0700)/",
  "Type":"Sitemap",
  "Url":"http://example.com/sitemap.xml",
  "UrlCount":1023
}]}
```

### GetFeedDetails

Get details for a specific feed (sitemap index entries).

- **HTTP**: `GET /GetFeedDetails?siteUrl={SITE_URL}&feedUrl={FEED_URL}&apikey={KEY}`
- **Returns**: Array of `Feed` objects (child entries)

### RemoveFeed

Remove a submitted feed.

- **HTTP**: `POST /RemoveFeed?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com","feedUrl":"http://example.com/sitemap.xml"}`

---

## Traffic and ranking statistics

### GetRankAndTrafficStats

Get daily impressions and clicks.

- **HTTP**: `GET /GetRankAndTrafficStats?siteUrl={SITE_URL}&apikey={KEY}`
- **Returns**: Array of `RankAndTrafficStats`
- **Updated**: Daily. Includes all verticals (Web, Chat, News, Images, Videos, Knowledge Panel) from March 24, 2023 onwards.

```json
{"d":[{
  "__type":"RankAndTrafficStats:#Microsoft.Bing.Webmaster.Api",
  "Clicks":15,
  "Date":"/Date(1316156400000-0700)/",
  "Impressions":100
}]}
```

### GetQueryStats

Get traffic stats for top queries.

- **HTTP**: `GET /GetQueryStats?siteUrl={SITE_URL}&apikey={KEY}`
- **Returns**: Array of `QueryStats`
- **Updated**: Weekly

```json
{"d":[{
  "__type":"QueryStats:#Microsoft.Bing.Webmaster.Api",
  "AvgClickPosition":18,
  "AvgImpressionPosition":17,
  "Clicks":15,
  "Date":"/Date(1316156400000-0700)/",
  "Impressions":100,
  "Query":"query"
}]}
```

### GetPageStats

Get traffic stats for top pages.

- **HTTP**: `GET /GetPageStats?siteUrl={SITE_URL}&apikey={KEY}`
- **Returns**: Array of `QueryStats` (where `Query` field contains the page URL)
- **Updated**: Weekly

### GetQueryTrafficStats

Get traffic stats for a specific query.

- **HTTP**: `GET /GetQueryTrafficStats?siteUrl={SITE_URL}&query={QUERY}&apikey={KEY}`
- **Returns**: Array of `RankAndTrafficStats`

### GetPageQueryStats

Get traffic stats for a specific page.

- **HTTP**: `GET /GetPageQueryStats?siteUrl={SITE_URL}&page={PAGE_URL}&apikey={KEY}`

### GetQueryPageStats

Get pages ranked for a specific query.

- **HTTP**: `GET /GetQueryPageStats?siteUrl={SITE_URL}&query={QUERY}&apikey={KEY}`

### GetQueryPageDetailStats

Get detailed stats for a specific query and page combination.

- **HTTP**: `GET /GetQueryPageDetailStats?siteUrl={SITE_URL}&query={QUERY}&page={PAGE_URL}&apikey={KEY}`

---

## Crawl monitoring

### GetCrawlStats

Get crawl statistics for the last 6 months.

- **HTTP**: `GET /GetCrawlStats?siteUrl={SITE_URL}&apikey={KEY}`
- **Returns**: Array of `CrawlStats`
- **Updated**: Daily

```json
{"d":[{
  "__type":"CrawlStats:#Microsoft.Bing.Webmaster.Api",
  "AllOtherCodes":0,
  "BlockedByRobotsTxt":0,
  "Code2xx":9998,
  "Code301":0,
  "Code302":0,
  "Code4xx":1,
  "Code5xx":1,
  "ContainsMalware":5,
  "CrawlErrors":0,
  "CrawledPages":0,
  "Date":"/Date(1316156400000-0700)/",
  "InIndex":1000,
  "InLinks":2048
}]}
```

### GetCrawlIssues

Get list of URLs with crawl issues.

- **HTTP**: `GET /GetCrawlIssues?siteUrl={SITE_URL}&apikey={KEY}`
- **Returns**: Array of `UrlWithCrawlIssues`
- **Remarks**: Fixed issues may take a few days to disappear.

```json
{"d":[{
  "__type":"UrlWithCrawlIssues:#Microsoft.Bing.Webmaster.Api",
  "HttpCode":200,
  "Issues":32,
  "Url":"http://example.com/url1.htm",
  "InLinks":10
}]}
```

### GetCrawlSettings

Get current crawl rate settings.

- **HTTP**: `GET /GetCrawlSettings?siteUrl={SITE_URL}&apikey={KEY}`
- **Returns**: `CrawlSettings`

### SaveCrawlSettings

Update crawl rate settings.

- **HTTP**: `POST /SaveCrawlSettings?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com","crawlSettings":{...}}`

---

## Index inspection

### GetUrlInfo

Get index details for a single page.

- **HTTP**: `GET /GetUrlInfo?siteUrl={SITE_URL}&url={URL}&apikey={KEY}`

### GetUrlTrafficInfo

Get traffic details for a single page.

- **HTTP**: `GET /GetUrlTrafficInfo?siteUrl={SITE_URL}&url={URL}&apikey={KEY}`

### GetChildrenUrlInfo

Get index details for URLs under a directory.

- **HTTP**: `GET /GetChildrenUrlInfo?siteUrl={SITE_URL}&url={DIR_URL}&page={PAGE_NUM}&apikey={KEY}`
- **Parameters**: `page` (UInt16) for pagination; optionally `filterProperties` for filtering

### GetChildrenUrlTrafficInfo

Get traffic details for URLs under a directory.

- **HTTP**: `GET /GetChildrenUrlTrafficInfo?siteUrl={SITE_URL}&url={DIR_URL}&page={PAGE_NUM}&apikey={KEY}`

### FetchUrl

Request Bing to fetch a specific URL.

- **HTTP**: `POST /FetchUrl?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com","url":"http://example.com/page.html"}`

### GetFetchedUrls

List URLs that were fetched on demand.

- **HTTP**: `GET /GetFetchedUrls?siteUrl={SITE_URL}&apikey={KEY}`

### GetFetchedUrlDetails

Get details of a fetched URL.

- **HTTP**: `GET /GetFetchedUrlDetails?siteUrl={SITE_URL}&url={URL}&apikey={KEY}`

---

## Keyword research

### GetKeyword

Get impressions for a keyword by country, language, and date range.

- **HTTP**: `GET /GetKeyword?q={QUERY}&country={COUNTRY}&language={LANG}&startDate={START}&endDate={END}&apikey={KEY}`
- **Returns**: `Keyword` object

### GetKeywordStats

Get historical statistics for a keyword.

- **HTTP**: `GET /GetKeywordStats?q={QUERY}&country={COUNTRY}&language={LANG}&apikey={KEY}`

### GetRelatedKeywords

Get related keyword impressions.

- **HTTP**: `GET /GetRelatedKeywords?q={QUERY}&country={COUNTRY}&language={LANG}&startDate={START}&endDate={END}&apikey={KEY}`

---

## Link analysis

### GetLinkCounts

Get pages with inbound links (paginated).

- **HTTP**: `GET /GetLinkCounts?siteUrl={SITE_URL}&page={PAGE_NUM}&apikey={KEY}`
- **Returns**: `LinkCounts` with `Links` array and `TotalPages`

```json
{"d":{
  "__type":"LinkCounts:#Microsoft.Bing.Webmaster.Api",
  "Links":[{"__type":"LinkCount:#Microsoft.Bing.Webmaster.Api","Count":14,"Url":"http://example.com/page1.html"}],
  "TotalPages":3
}}
```

### GetUrlLinks

Get inbound links for a specific URL.

- **HTTP**: `GET /GetUrlLinks?siteUrl={SITE_URL}&url={URL}&page={PAGE_NUM}&apikey={KEY}`

---

## URL blocking

### AddBlockedUrl

Block a page or directory from Bing search results.

- **HTTP**: `POST /AddBlockedUrl?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com","blockedUrl":{...}}`

### GetBlockedUrls

List currently blocked URLs.

- **HTTP**: `GET /GetBlockedUrls?siteUrl={SITE_URL}&apikey={KEY}`

### RemoveBlockedUrl

Unblock a previously blocked URL.

- **HTTP**: `POST /RemoveBlockedUrl?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com","blockedUrl":{...}}`

---

## Page preview blocking

### AddPagePreviewBlock

Block page preview/snapshot for a URL.

- **HTTP**: `POST /AddPagePreviewBlock?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com","url":"http://example.com/page.html","blockReason":"..."}`

### GetActivePagePreviewBlocks

List active page preview blocks.

- **HTTP**: `GET /GetActivePagePreviewBlocks?siteUrl={SITE_URL}&apikey={KEY}`

### RemovePagePreviewBlock

Remove a page preview block.

- **HTTP**: `POST /RemovePagePreviewBlock?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com","url":"http://example.com/page.html"}`

---

## Deep link management

> Note: `GetDeepLink` and `GetDeepLinkAlgoUrls` are marked **Obsolete**.

### GetDeepLinkBlocks

List deep link blocks.

- **HTTP**: `GET /GetDeepLinkBlocks?siteUrl={SITE_URL}&apikey={KEY}`

### AddDeepLinkBlock

Add a deep link block.

- **HTTP**: `POST /AddDeepLinkBlock?apikey={KEY}`

### RemoveDeepLinkBlock

Remove a deep link block.

- **HTTP**: `POST /RemoveDeepLinkBlock?apikey={KEY}`

---

## URL normalization

### GetQueryParameters

List URL normalization parameters.

- **HTTP**: `GET /GetQueryParameters?siteUrl={SITE_URL}&apikey={KEY}`

### AddQueryParameter

Add a URL normalization parameter.

- **HTTP**: `POST /AddQueryParameter?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com","queryParameter":"utm_source"}`

### RemoveQueryParameter

Remove a URL normalization parameter.

- **HTTP**: `POST /RemoveQueryParameter?apikey={KEY}`

### EnableDisableQueryParameter

Toggle a URL normalization parameter on/off.

- **HTTP**: `POST /EnableDisableQueryParameter?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com","queryParameter":"utm_source","isEnabled":true}`

---

## Country/region settings

### GetCountryRegionSettings

- **HTTP**: `GET /GetCountryRegionSettings?siteUrl={SITE_URL}&apikey={KEY}`

### AddCountryRegionSettings

- **HTTP**: `POST /AddCountryRegionSettings?apikey={KEY}`

### RemoveCountryRegionSettings

- **HTTP**: `POST /RemoveCountryRegionSettings?apikey={KEY}`

---

## Site roles

### GetSiteRoles

Get delegated access roles for a site.

- **HTTP**: `GET /GetSiteRoles?siteUrl={SITE_URL}&includeAssociatedUsers={BOOL}&apikey={KEY}`

### AddSiteRoles

Delegate site access to a user.

- **HTTP**: `POST /AddSiteRoles?apikey={KEY}`

### RemoveSiteRole

Remove a user's site access.

- **HTTP**: `POST /RemoveSiteRole?apikey={KEY}`

---

## Site moves

### GetSiteMoves

- **HTTP**: `GET /GetSiteMoves?siteUrl={SITE_URL}&apikey={KEY}`

### SubmitSiteMove

- **HTTP**: `POST /SubmitSiteMove?apikey={KEY}`

---

## Connected pages

### GetConnectedPages

- **HTTP**: `GET /GetConnectedPages?siteUrl={SITE_URL}&apikey={KEY}`

### AddConnectedPage

Add a page linked to your website.

- **HTTP**: `POST /AddConnectedPage?apikey={KEY}`
- **Body**: `{"siteUrl":"http://example.com","url":"http://partner.com/page"}`
