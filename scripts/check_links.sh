#!/usr/bin/env bash
# =============================================================================
# check_links.sh - Verify all links in HTML files are reachable
# =============================================================================
#
# WHAT THIS DOES:
# Scans every HTML file for href and src attributes, then verifies:
# 1. LOCAL links: the referenced file actually exists on disk
# 2. EXTERNAL links: the URL returns a 2xx or 3xx HTTP status
#
# WHY NOT USE A DEDICATED TOOL (like htmltest or lychee)?
# For a small portfolio site, a bash script is simpler to understand, has
# zero dependencies beyond curl/grep (already on any CI runner), and gives
# us full control over timeout/retry behavior. For larger sites (100+ pages),
# switch to a purpose-built link checker.
#
# DESIGN DECISIONS:
# - External timeouts → warning (not failure). We don't want a CDN blip or
#   LinkedIn rate-limiting to block our deploy.
# - Bot-protection responses (403/429/999) → warning. These say "we don't serve
#   automated clients", not "this link is broken". LinkedIn answers CI traffic
#   with 999 and Cloudflare-fronted hosts answer with 403; failing on them makes
#   our deploy depend on a third party's bot policy rather than on our own site.
# - Other external 4xx/5xx → error. If a link is definitively broken, fail.
# - Anchors (#), data URIs, mailto:, tel:, javascript: → skipped entirely.
#   These don't resolve to network resources.
#
# EXIT BEHAVIOR:
# - Exit 0: All links valid (or only timeouts, which are treated as warnings)
# - Exit 1: At least one definitively broken link found
#
# DEPENDENCIES: curl, grep (both available on ubuntu-latest)
# =============================================================================

# Strict mode (see validate_html.sh for explanation of each flag)
set -euo pipefail

SITE_DIR="${SITE_DIR:-site}"
ERRORS_FOUND=0
CHECKED=0

# Timeout for external URL checks. 10s is generous enough for slow servers
# but won't stall the pipeline for minutes on truly dead hosts.
EXTERNAL_TIMEOUT=10

echo "🔗 Checking links in ${SITE_DIR}/"
echo "───────────────────────────────────────"

# Locate all HTML files to scan
HTML_FILES=$(find "$SITE_DIR" -name "*.html" -type f)

if [ -z "$HTML_FILES" ]; then
    echo "⚠️  No HTML files found in ${SITE_DIR}/"
    exit 1
fi

for file in $HTML_FILES; do
    echo ""
    echo "Scanning: $file"

    # Get the directory containing this HTML file - needed for resolving
    # relative paths (e.g., href="styles.css" resolves relative to the HTML file)
    FILE_DIR=$(dirname "$file")

    # Extract link targets from href="..." and src="..." attributes.
    # Using grep -oP with a lookbehind to capture just the URL value.
    #
    # LIMITATION: This is regex-based, not a real HTML parser. It won't
    # handle edge cases like multi-line attributes or links constructed
    # via JavaScript. For a static portfolio site, this is sufficient.
    LINKS=$(grep -oP '(?:href|src)=["'\'']\K[^"'\'']+' "$file" 2>/dev/null || true)

    if [ -z "$LINKS" ]; then
        echo "  (no links found)"
        continue
    fi

    while IFS= read -r link; do
        CHECKED=$((CHECKED + 1))

        # ─── SKIP NON-NETWORK REFERENCES ─────────────────────────────────
        # These are valid HTML but don't point to fetchable resources:
        # - # (page anchors)
        # - data: (inline base64 content)
        # - mailto: / tel: (protocol handlers)
        # - javascript: (inline scripts, shouldn't exist but skip gracefully)
        if [[ "$link" =~ ^(#|data:|mailto:|tel:|javascript:) ]]; then
            continue
        fi

        # ─── CHECK EXTERNAL URLs ─────────────────────────────────────────
        # For https:// and http:// links, make a HEAD-like request with curl.
        # -o /dev/null: discard response body (we only care about status code)
        # -s: silent mode (no progress bar)
        # -w "%{http_code}": output just the HTTP status code
        # -L: follow redirects (important for shortened URLs)
        # --max-time: give up after EXTERNAL_TIMEOUT seconds
        if [[ "$link" =~ ^https?:// ]]; then
            # BUG FIX: the previous form was
            #     HTTP_CODE=$(curl ... || echo "000")
            # On a failed transfer curl writes its "%{http_code}" template to
            # stdout ("000") AND exits non-zero, so the `|| echo "000"` fired as
            # well and the substitution captured "000" + "000" = "000000".
            # That value matched neither the 2xx/3xx pattern nor the "000"
            # timeout branch, so every unreachable host fell through to the
            # "definitively broken" case and hard-failed the deploy - the exact
            # opposite of the documented behaviour above. Capture curl's output
            # and its exit status separately, then normalise.
            HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" \
                --max-time "$EXTERNAL_TIMEOUT" \
                -L "$link" 2>/dev/null) || true
            # Anything curl could not turn into a three-digit status collapses
            # to the "unreachable" sentinel.
            [[ "$HTTP_CODE" =~ ^[0-9]{3}$ ]] || HTTP_CODE="000"

            if [[ "$HTTP_CODE" =~ ^(2|3)[0-9][0-9]$ ]]; then
                # 2xx (success) or 3xx (redirect) - link is alive
                echo "  ✅ ${link} (${HTTP_CODE})"
            elif [ "$HTTP_CODE" = "000" ]; then
                # Timeout or DNS failure. Warn but don't fail - this might be
                # a CI network issue, not a broken link.
                echo "  ⚠️  ${link} (timeout/unreachable - skipping)"
            elif [[ "$HTTP_CODE" =~ ^(403|429|999)$ ]]; then
                # Bot protection or rate limiting. The host is up and the URL
                # resolves; it just refuses automated clients. Not our bug, and
                # not worth blocking a deploy over.
                echo "  ⚠️  ${link} (HTTP ${HTTP_CODE} - bot protection/rate limit, not treated as broken)"
            else
                # 4xx (not found) or 5xx (server error) - definitively broken
                echo "  ❌ ${link} (HTTP ${HTTP_CODE})"
                ERRORS_FOUND=1
            fi
            continue
        fi

        # ─── CHECK LOCAL FILE REFERENCES ─────────────────────────────────
        # For relative paths (e.g., "styles.css", "assets/photo.jpg"),
        # verify the file exists on disk relative to the HTML file's location.
        LOCAL_PATH="${FILE_DIR}/${link}"

        # Handle root-relative paths (starting with /).
        # These resolve from the site root, not the HTML file's directory.
        if [[ "$link" =~ ^/ ]]; then
            LOCAL_PATH="${SITE_DIR}${link}"
        fi

        # Check if the path exists as either a file or directory
        # (directories are valid for links like href="assets/")
        if [ -f "$LOCAL_PATH" ] || [ -d "$LOCAL_PATH" ]; then
            echo "  ✅ ${link} (local file exists)"
        else
            echo "  ❌ ${link} (file not found: ${LOCAL_PATH})"
            ERRORS_FOUND=1
        fi

    done <<< "$LINKS"
done

echo ""
echo "───────────────────────────────────────"
echo "Checked ${CHECKED} links total."

if [ "$ERRORS_FOUND" -eq 1 ]; then
    echo "❌ Broken links found. Fix them before deploying."
    exit 1
fi

echo "✅ All links valid."
exit 0
