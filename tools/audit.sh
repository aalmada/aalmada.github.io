#!/usr/bin/env bash
#
# Run Lighthouse, Bing Webmaster, and Clarity audits against the live site.
#
# Prerequisites:
#   npm install -g lighthouse
#   source .env   (for BING_WEBMASTER_API_KEY and CLARITY_API_TOKEN)
#
# Usage:
#   bash tools/audit.sh                    # audit homepage only
#   bash tools/audit.sh <url>              # audit a specific URL
#   bash tools/audit.sh --full             # audit homepage + latest post

set -euo pipefail

SITE_URL="https://antaoalmada.dev"
SITE_URL_SLASH="${SITE_URL}/"
REPORTS_DIR="_reports"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

score_color() {
  local score=$1
  if (( score >= 90 )); then echo -e "${GREEN}${score}${NC}"
  elif (( score >= 50 )); then echo -e "${ORANGE}${score}${NC}"
  else echo -e "${RED}${score}${NC}"; fi
}

header() {
  echo ""
  echo -e "${BOLD}${CYAN}━━━ $1 ━━━${NC}"
}

# ── Parse arguments ───────────────────────────────────────────────────────────
URLS=("${SITE_URL}/")
FULL_MODE=false

if [[ "${1:-}" == "--full" ]]; then
  FULL_MODE=true
  # Pick the latest post from the sitemap
  LATEST_POST=$(curl -s "${SITE_URL}/sitemap.xml" \
    | grep -oP '(?<=<loc>)[^<]+/posts/[^<]+' \
    | tail -1)
  if [[ -n "$LATEST_POST" ]]; then
    URLS+=("$LATEST_POST")
  fi
elif [[ -n "${1:-}" ]]; then
  URLS=("$1")
fi

mkdir -p "$REPORTS_DIR"

# ══════════════════════════════════════════════════════════════════════════════
# 1. LIGHTHOUSE
# ══════════════════════════════════════════════════════════════════════════════
header "Lighthouse Audit"

if ! command -v lighthouse &>/dev/null; then
  echo -e "${RED}lighthouse CLI not found. Install with: npm install -g lighthouse${NC}"
else
  for url in "${URLS[@]}"; do
    # Sanitize URL into a filename
    slug=$(echo "$url" | sed 's|https\?://||;s|/|_|g;s|_$||')
    json_path="${REPORTS_DIR}/lighthouse-${slug}.json"
    html_path="${REPORTS_DIR}/lighthouse-${slug}.html"

    echo "Auditing: $url"

    # Run JSON and HTML as separate passes to avoid output naming issues
    lighthouse "$url" \
      --output json \
      --output-path "$json_path" \
      --chrome-flags="--headless --no-sandbox --disable-gpu --disable-dev-shm-usage --ignore-certificate-errors" \
      --quiet 2>/dev/null || true

    lighthouse "$url" \
      --output html \
      --output-path "$html_path" \
      --chrome-flags="--headless --no-sandbox --disable-gpu --disable-dev-shm-usage --ignore-certificate-errors" \
      --quiet 2>/dev/null || true

    if [[ -f "$json_path" ]]; then
      scores=$(python3 -c "
import json
with open('$json_path') as f:
    lhr = json.load(f)
cats = lhr.get('categories', {})
for name in ['performance', 'accessibility', 'best-practices', 'seo']:
    cat = cats.get(name, {})
    score = int((cat.get('score', 0) or 0) * 100)
    print(f'{name}:{score}')
")
      echo "  ┌──────────────────┬───────┐"
      echo "  │ Category         │ Score │"
      echo "  ├──────────────────┼───────┤"
      while IFS=: read -r cat score; do
        padded=$(printf '%-16s' "$cat")
        colored=$(score_color "$score")
        echo -e "  │ ${padded} │  ${colored}  │"
      done <<< "$scores"
      echo "  └──────────────────┴───────┘"
      echo "  Reports: $json_path, $html_path"
    else
      echo -e "  ${RED}Failed to generate report${NC}"
    fi
    echo ""
  done
fi

# ══════════════════════════════════════════════════════════════════════════════
# 2. BING WEBMASTER — Crawl Health
# ══════════════════════════════════════════════════════════════════════════════
header "Bing Webmaster — Crawl Health"

if [[ -z "${BING_WEBMASTER_API_KEY:-}" ]]; then
  echo -e "${RED}BING_WEBMASTER_API_KEY not set. Run: source .env${NC}"
else
  BING_BASE="https://ssl.bing.com/webmaster/api.svc/json"

  # Crawl stats (last 3 days)
  echo "Recent crawl stats:"
  curl -s "${BING_BASE}/GetCrawlStats?siteUrl=${SITE_URL_SLASH}&apikey=${BING_WEBMASTER_API_KEY}" \
    | sed 's/^\xef\xbb\xbf//' \
    | python3 -c "
import json, sys, datetime
data = json.loads(sys.stdin.read()).get('d', [])
if not data:
    print('  No crawl stats available')
else:
    print('  ┌────────────┬──────┬──────┬──────┬──────┬─────────┬─────────┐')
    print('  │ Date       │  2xx │  301 │  4xx │  5xx │ InIndex │ Errors  │')
    print('  ├────────────┼──────┼──────┼──────┼──────┼─────────┼─────────┤')
    for entry in data[-5:]:
        ts = int(entry['Date'].split('(')[1].split('-')[0].split('+')[0]) / 1000
        dt = datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc).strftime('%Y-%m-%d')
        c2 = entry.get('Code2xx', 0)
        c301 = entry.get('Code301', 0)
        c4 = entry.get('Code4xx', 0)
        c5 = entry.get('Code5xx', 0)
        idx = entry.get('InIndex', 0)
        err = entry.get('CrawlErrors', 0)
        print(f'  │ {dt} │ {c2:>4} │ {c301:>4} │ {c4:>4} │ {c5:>4} │ {idx:>7} │ {err:>7} │')
    print('  └────────────┴──────┴──────┴──────┴──────┴─────────┴─────────┘')
" 2>/dev/null || echo -e "  ${RED}Failed to fetch crawl stats${NC}"

  echo ""

  # Crawl issues
  echo "Crawl issues:"
  curl -s "${BING_BASE}/GetCrawlIssues?siteUrl=${SITE_URL_SLASH}&apikey=${BING_WEBMASTER_API_KEY}" \
    | sed 's/^\xef\xbb\xbf//' \
    | python3 -c "
import json, sys
data = json.loads(sys.stdin.read()).get('d', [])
if not data:
    print('  ✓ No crawl issues found')
else:
    print(f'  ✗ {len(data)} crawl issue(s):')
    for issue in data[:20]:
        url = issue.get('Url', '?')
        code = issue.get('HttpCode', '?')
        print(f'    {code} → {url}')
" 2>/dev/null || echo -e "  ${RED}Failed to fetch crawl issues${NC}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# 3. CLARITY — Traffic Summary
# ══════════════════════════════════════════════════════════════════════════════
header "Clarity — Traffic Summary (last 24h)"

if [[ -z "${CLARITY_API_TOKEN:-}" ]]; then
  echo "  CLARITY_API_TOKEN not set — skipping."
  echo "  Generate at: Clarity dashboard → Settings → Data Export → Generate new API token"
  echo "  Then add to .env: CLARITY_API_TOKEN='your-token'"
else
  curl -s "https://www.clarity.ms/export-data/api/v1/project-live-insights?numOfDays=1" \
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
            total_sessions = sum(int(i.get('totalSessionCount', 0)) for i in info)
            total_users = sum(int(i.get('distantUserCount', 0)) for i in info)
            bot_sessions = sum(int(i.get('totalBotSessionCount', 0)) for i in info)
            print(f'  Sessions: {total_sessions:,}  |  Users: {total_users:,}  |  Bot sessions: {bot_sessions:,}')
            break
    else:
        print('  No traffic data in response')
else:
    msg = data.get('Message', data.get('message', str(data)))
    print(f'  Error: {msg}')
" 2>/dev/null || echo -e "  ${RED}Failed to fetch Clarity data${NC}"
fi

echo ""
echo -e "${BOLD}Done.${NC} Full reports saved to ${REPORTS_DIR}/"
