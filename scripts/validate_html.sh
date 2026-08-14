#!/usr/bin/env bash
# =============================================================================
# validate_html.sh — HTML quality gate using W3C's HTML Tidy
# =============================================================================
#
# WHAT THIS DOES:
# Finds all .html files in the site directory and runs them through HTML Tidy
# in validation mode. Tidy checks for:
# - Unclosed/mismatched tags
# - Missing required attributes (alt, lang, etc.)
# - Invalid nesting (e.g., <p> inside <p>)
# - Deprecated elements
#
# EXIT BEHAVIOR:
# - Exit 0: All files pass (errors = 0, warnings are OK)
# - Exit 1: At least one file has errors, OR no HTML files found
#
# DESIGN DECISION — WARNINGS VS ERRORS:
# We intentionally allow warnings through. Tidy is opinionated about things
# like implicit <body> tags and proprietary attributes (e.g., aria-label in
# older tidy versions). Failing on warnings would create too much friction
# for a portfolio site. Errors (malformed markup) always block.
#
# DEPENDENCY: tidy (installed via `apt-get install tidy` in the workflow)
# =============================================================================

# Strict mode:
# -e: exit on any command failure
# -u: treat unset variables as errors
# -o pipefail: catch failures in piped commands
set -euo pipefail

# Allow the site directory to be overridden via environment variable.
# The deploy workflow sets SITE_DIR globally; default to "site" for local runs.
SITE_DIR="${SITE_DIR:-site}"

# Track whether any file had actual errors (exit code 2 from tidy)
ERRORS_FOUND=0

echo "🔍 Validating HTML files in ${SITE_DIR}/"
echo "───────────────────────────────────────"

# BUG FIX: guard on the validator itself being present.
# Without this check, `TIDY_OUTPUT=$(tidy ...)` exits 127 ("command not found").
# 127 is neither 1 (warnings) nor 2 (errors), so every file fell through to the
# final `else` and was reported "✅ Valid" — the gate passed while validating
# nothing at all. A quality gate that cannot run must fail, not pass.
if ! command -v tidy >/dev/null 2>&1; then
    echo "❌ 'tidy' is not installed — cannot validate HTML."
    echo "   Install it with: sudo apt-get install -y tidy"
    exit 1
fi

# Recursively find all HTML files. Using -type f ensures we skip directories
# that happen to end in .html (unlikely but defensive).
HTML_FILES=$(find "$SITE_DIR" -name "*.html" -type f)

# Guard: if there are no HTML files, something is wrong with the repo structure.
# Fail loudly rather than silently passing an empty check.
if [ -z "$HTML_FILES" ]; then
    echo "⚠️  No HTML files found in ${SITE_DIR}/"
    exit 1
fi

for file in $HTML_FILES; do
    echo ""
    echo "Checking: $file"

    # Run tidy in errors-only mode.
    # Tidy exit codes:
    #   0 = no warnings or errors
    #   1 = warnings only (we allow these)
    #   2 = errors found (these block the deploy)
    #
    # We capture stderr (where tidy writes diagnostics) into TIDY_OUTPUT.
    # The "|| TIDY_EXIT=$?" pattern captures the exit code without triggering
    # set -e (which would abort the script on non-zero exit).
    #
    # BUG FIX: reset TIDY_EXIT at the top of every iteration.
    # The old code relied on `TIDY_EXIT=${TIDY_EXIT:-0}`, but `:-` only
    # substitutes when the variable is *unset*. Once any file failed, TIDY_EXIT
    # stayed set to 2, and `|| TIDY_EXIT=$?` never fires on success — so every
    # subsequent clean file inherited the stale 2 and was reported as broken.
    TIDY_EXIT=0
    TIDY_OUTPUT=$(tidy -errors -quiet "$file" 2>&1) || TIDY_EXIT=$?

    if [ "$TIDY_EXIT" -eq 2 ]; then
        # ERRORS: Malformed HTML that browsers may render incorrectly.
        # These must be fixed before deploying.
        echo "  ❌ ERRORS found:"
        echo "$TIDY_OUTPUT" | sed 's/^/     /'
        ERRORS_FOUND=1
    elif [ "$TIDY_EXIT" -eq 1 ]; then
        # WARNINGS: Valid but questionable HTML. Show first 5 to avoid
        # flooding the log, then indicate how many more there are.
        echo "  ⚠️  Warnings (non-blocking):"
        echo "$TIDY_OUTPUT" | head -5 | sed 's/^/     /'
        WARN_COUNT=$(echo "$TIDY_OUTPUT" | wc -l)
        if [ "$WARN_COUNT" -gt 5 ]; then
            echo "     ... and $((WARN_COUNT - 5)) more warnings"
        fi
    elif [ "$TIDY_EXIT" -gt 2 ]; then
        # Anything above 2 means tidy itself failed to run properly (bad flags,
        # unreadable file, killed process). Treat it as a blocking failure
        # rather than silently assuming the file is fine.
        echo "  ❌ tidy exited unexpectedly (code ${TIDY_EXIT}):"
        echo "$TIDY_OUTPUT" | sed 's/^/     /'
        ERRORS_FOUND=1
    else
        # Clean pass — no issues at all.
        echo "  ✅ Valid"
    fi
done

echo ""
echo "───────────────────────────────────────"

# Final verdict: fail the pipeline if ANY file had errors.
if [ "$ERRORS_FOUND" -eq 1 ]; then
    echo "❌ HTML validation failed. Fix errors above before deploying."
    exit 1
fi

echo "✅ All HTML files passed validation."
exit 0
