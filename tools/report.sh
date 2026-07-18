#!/usr/bin/env bash
#
# Generate a combined quality report from Lighthouse, Bing Webmaster, and Clarity.
# Outputs formatted Markdown to stdout.
#
# Prerequisites:
#   source .env   (for BING_WEBMASTER_API_KEY and CLARITY_API_TOKEN)
#
# Usage:
#   bash tools/report.sh              # print to terminal
#   bash tools/report.sh > report.md  # save to file

set -euo pipefail

SITE_URL="https://antaoalmada.dev"
SITE_URL_SLASH="${SITE_URL}/"
REPORTS_DIR="_reports"
BING_BASE="https://ssl.bing.com/webmaster/api.svc/json"

echo "# Site Quality Report — $(date -u '+%Y-%m-%d %H:%M UTC')"
echo ""
echo "Site: ${SITE_URL}"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# 1. LIGHTHOUSE (from latest local report)
# ══════════════════════════════════════════════════════════════════════════════
echo "## Lighthouse Scores"
echo ""

latest_report=$(ls -t "${REPORTS_DIR}"/lighthouse-*.json 2>/dev/null | head -1 || true)
if [[ -n "$latest_report" ]]; then
  python3 -c "
import json
with open('$latest_report') as f:
    lhr = json.load(f)
url = lhr.get('finalDisplayedUrl', lhr.get('requestedUrl', '?'))
ts = lhr.get('fetchTime', '?')
print(f'URL: {url}')
print(f'Tested: {ts}')
print()
print('| Category | Score |')
print('|----------|-------|')
cats = lhr.get('categories', {})
for name in ['performance', 'accessibility', 'best-practices', 'seo']:
    cat = cats.get(name, {})
    score = int((cat.get('score', 0) or 0) * 100)
    icon = '🟢' if score >= 90 else ('🟡' if score >= 50 else '🔴')
    print(f'| {name} | {icon} {score} |')
"
else
  echo "_No Lighthouse reports found in \`${REPORTS_DIR}/\`. Run \`bash tools/audit.sh\` first._"
fi
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# 2. BING WEBMASTER — Crawl Stats
# ══════════════════════════════════════════════════════════════════════════════
echo "## Bing Webmaster — Crawl Stats (last 5 days)"
echo ""

if [[ -z "${BING_WEBMASTER_API_KEY:-}" ]]; then
  echo "_BING_WEBMASTER_API_KEY not set. Run \`source .env\`._"
else
  curl -s "${BING_BASE}/GetCrawlStats?siteUrl=${SITE_URL_SLASH}&apikey=${BING_WEBMASTER_API_KEY}" \
    | sed 's/^\xef\xbb\xbf//' \
    | python3 -c "
import json, sys, datetime
data = json.loads(sys.stdin.read()).get('d', [])
if not data:
    print('_No crawl stats available._')
else:
    print('| Date | 2xx | 301 | 4xx | 5xx | In Index | Errors |')
    print('|------|-----|-----|-----|-----|---------|--------|')
    for entry in data[-5:]:
        ts = int(entry['Date'].split('(')[1].split('-')[0].split('+')[0]) / 1000
        dt = datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc).strftime('%Y-%m-%d')
        print(f\"| {dt} | {entry.get('Code2xx',0)} | {entry.get('Code301',0)} | {entry.get('Code4xx',0)} | {entry.get('Code5xx',0)} | {entry.get('InIndex',0)} | {entry.get('CrawlErrors',0)} |\")
" 2>/dev/null || echo "_Failed to fetch crawl stats._"

  echo ""

  # Crawl issues
  echo "### Crawl Issues"
  echo ""
  curl -s "${BING_BASE}/GetCrawlIssues?siteUrl=${SITE_URL_SLASH}&apikey=${BING_WEBMASTER_API_KEY}" \
    | sed 's/^\xef\xbb\xbf//' \
    | python3 -c "
import json, sys
data = json.loads(sys.stdin.read()).get('d', [])
if not data:
    print('No crawl issues. ✓')
else:
    print(f'{len(data)} issue(s):')
    print()
    print('| HTTP Code | URL |')
    print('|-----------|-----|')
    for issue in data[:20]:
        print(f\"| {issue.get('HttpCode','?')} | {issue.get('Url','?')} |\")
" 2>/dev/null || echo "_Failed to fetch crawl issues._"

  echo ""

  # Top queries
  echo "### Top Queries (by impressions)"
  echo ""
  curl -s "${BING_BASE}/GetQueryStats?siteUrl=${SITE_URL_SLASH}&apikey=${BING_WEBMASTER_API_KEY}" \
    | sed 's/^\xef\xbb\xbf//' \
    | python3 -c "
import json, sys
data = json.loads(sys.stdin.read()).get('d', [])
if not data:
    print('_No query stats available._')
else:
    queries = {}
    for e in data:
        q = e.get('Query', '')
        if q not in queries:
            queries[q] = {'imp': 0, 'clicks': 0}
        queries[q]['imp'] += e.get('Impressions', 0)
        queries[q]['clicks'] += e.get('Clicks', 0)
    top = sorted(queries.items(), key=lambda x: x[1]['imp'], reverse=True)[:10]
    print('| Query | Impressions | Clicks |')
    print('|-------|-------------|--------|')
    for q, s in top:
        print(f\"| {q} | {s['imp']} | {s['clicks']} |\")
" 2>/dev/null || echo "_Failed to fetch query stats._"

  echo ""

  # Top pages
  echo "### Top Pages (by impressions)"
  echo ""
  curl -s "${BING_BASE}/GetPageStats?siteUrl=${SITE_URL_SLASH}&apikey=${BING_WEBMASTER_API_KEY}" \
    | sed 's/^\xef\xbb\xbf//' \
    | python3 -c "
import json, sys
data = json.loads(sys.stdin.read()).get('d', [])
if not data:
    print('_No page stats available._')
else:
    pages = {}
    for e in data:
        p = e.get('Query', '')
        if p not in pages:
            pages[p] = {'imp': 0, 'clicks': 0}
        pages[p]['imp'] += e.get('Impressions', 0)
        pages[p]['clicks'] += e.get('Clicks', 0)
    top = sorted(pages.items(), key=lambda x: x[1]['imp'], reverse=True)[:10]
    print('| Page | Impressions | Clicks |')
    print('|------|-------------|--------|')
    for p, s in top:
        short = p.replace('${SITE_URL}', '')
        print(f\"| {short} | {s['imp']} | {s['clicks']} |\")
" 2>/dev/null || echo "_Failed to fetch page stats._"
fi

echo ""

# ══════════════════════════════════════════════════════════════════════════════
# 3. CLARITY — Traffic Summary
# ══════════════════════════════════════════════════════════════════════════════
echo "## Clarity — Traffic (last 3 days)"
echo ""

if [[ -z "${CLARITY_API_TOKEN:-}" ]]; then
  echo "_CLARITY_API_TOKEN not set — skipping. Generate at Clarity dashboard → Settings → Data Export._"
else
  curl -s "https://www.clarity.ms/export-data/api/v1/project-live-insights?numOfDays=3&dimension1=Device" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${CLARITY_API_TOKEN}" \
    | python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
if isinstance(data, list):
    for metric in data:
        name = metric.get('metricName', '?')
        info = metric.get('information', [])
        if name == 'Traffic' and info:
            print('| Device | Sessions | Users | Bot Sessions |')
            print('|--------|----------|-------|--------------|')
            for i in info:
                device = i.get('Device', 'Unknown')
                sessions = int(i.get('totalSessionCount', 0))
                users = int(i.get('distantUserCount', 0))
                bots = int(i.get('totalBotSessionCount', 0))
                print(f'| {device} | {sessions:,} | {users:,} | {bots:,} |')
            break
    else:
        print('_No traffic data in response._')
else:
    msg = data.get('Message', data.get('message', str(data)))
    print(f'Error: {msg}')
" 2>/dev/null || echo "_Failed to fetch Clarity data._"
fi

echo ""
echo "---"
echo "_Generated by \`tools/report.sh\` on $(date -u '+%Y-%m-%d %H:%M UTC')_"
