#!/bin/bash
# Reconcile spec documents with GitHub issues
# Usage: ./scripts/reconcile-specs.sh [--apply]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

APPLY=false
if [ "$1" = "--apply" ]; then
    APPLY=true
fi

echo "=========================================="
echo "Spec Reconciliation"
echo "=========================================="
echo ""
echo "Apply changes: $APPLY"
echo ""

# Check gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) not installed${NC}"
    exit 1
fi

if ! gh auth status &> /dev/null 2>&1; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Arrays to track differences
declare -a SPEC_DONE_GITHUB_OPEN
declare -a SPEC_PENDING_GITHUB_CLOSED
declare -a NO_GITHUB_ISSUE
declare -a CONSISTENT

# Function to get spec status
get_spec_status() {
    local story_id="$1"
    local platform="$2"
    local file="$PROJECT_ROOT/specs/requirements/${platform}.md"

    if [ ! -f "$file" ]; then
        echo "unknown"
        return
    fi

    local line=$(grep "| $story_id |" "$file" 2>/dev/null || true)

    if [[ "$line" == *"Done"* ]] || [[ "$line" == *"🟢"* ]]; then
        echo "done"
    elif [[ "$line" == *"In Progress"* ]] || [[ "$line" == *"🟡"* ]]; then
        echo "in_progress"
    elif [[ "$line" == *"Pending"* ]] || [[ "$line" == *"🔴"* ]]; then
        echo "pending"
    else
        echo "unknown"
    fi
}

# Function to get GitHub issue state
get_github_state() {
    local story_id="$1"

    # Search for issues with story label
    local result=$(gh issue list --state all --label "story:$story_id" --json number,state --jq '.[0]' 2>/dev/null || echo "null")

    if [ "$result" = "null" ] || [ -z "$result" ]; then
        echo "none"
        return
    fi

    local state=$(echo "$result" | jq -r '.state')
    local number=$(echo "$result" | jq -r '.number')

    echo "${state}:#${number}"
}

# Process stories
process_stories() {
    local platform="$1"
    local prefix="$2"

    echo -e "${BLUE}Processing $platform stories...${NC}"
    echo ""

    local file="$PROJECT_ROOT/specs/requirements/${platform}.md"

    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}File not found: $file${NC}"
        return
    fi

    # Extract story IDs
    local story_ids=$(grep -oE "\| ${prefix}[0-9]+ \|" "$file" | grep -oE "${prefix}[0-9]+" | sort -u)

    for story_id in $story_ids; do
        local spec_status=$(get_spec_status "$story_id" "$platform")
        local github_info=$(get_github_state "$story_id")
        local github_state="${github_info%%:*}"
        local github_issue="${github_info#*:}"

        printf "  %-6s spec=%-12s github=%-8s %s\n" "$story_id" "$spec_status" "$github_state" "$github_issue"

        # Categorize
        if [ "$github_state" = "none" ]; then
            NO_GITHUB_ISSUE+=("$story_id:$platform:$spec_status")
        elif [ "$spec_status" = "done" ] && [ "$github_state" = "OPEN" ]; then
            SPEC_DONE_GITHUB_OPEN+=("$story_id:$platform:$github_issue")
        elif [ "$spec_status" = "pending" ] && [ "$github_state" = "CLOSED" ]; then
            SPEC_PENDING_GITHUB_CLOSED+=("$story_id:$platform:$github_issue")
        else
            CONSISTENT+=("$story_id:$platform")
        fi
    done

    echo ""
}

# Process both platforms
process_stories "mobile" "M"
process_stories "web" "W"

# Summary
echo "=========================================="
echo "Reconciliation Summary"
echo "=========================================="
echo ""

echo -e "${GREEN}Consistent: ${#CONSISTENT[@]}${NC}"
for item in "${CONSISTENT[@]}"; do
    echo "  - ${item%%:*}"
done
echo ""

echo -e "${YELLOW}No GitHub Issue: ${#NO_GITHUB_ISSUE[@]}${NC}"
for item in "${NO_GITHUB_ISSUE[@]}"; do
    IFS=':' read -r story_id platform status <<< "$item"
    echo "  - $story_id ($platform): spec=$status, no issue"
done
echo ""

echo -e "${RED}Spec Done, GitHub Open: ${#SPEC_DONE_GITHUB_OPEN[@]}${NC}"
for item in "${SPEC_DONE_GITHUB_OPEN[@]}"; do
    IFS=':' read -r story_id platform issue <<< "$item"
    echo "  - $story_id ($platform): $issue should be closed"
done
echo ""

echo -e "${RED}Spec Pending, GitHub Closed: ${#SPEC_PENDING_GITHUB_CLOSED[@]}${NC}"
for item in "${SPEC_PENDING_GITHUB_CLOSED[@]}"; do
    IFS=':' read -r story_id platform issue <<< "$item"
    echo "  - $story_id ($platform): spec should be updated to Done"
done
echo ""

# Apply changes
if [ "$APPLY" = "true" ]; then
    echo "=========================================="
    echo "Applying Changes"
    echo "=========================================="
    echo ""

    # Close GitHub issues for Done specs
    for item in "${SPEC_DONE_GITHUB_OPEN[@]}"; do
        IFS=':' read -r story_id platform issue <<< "$item"
        issue_num="${issue#\#}"
        echo "Closing issue $issue for $story_id..."
        gh issue close "$issue_num" --comment "Auto-closed: Story marked as Done in spec"
    done

    # Update specs for closed issues
    for item in "${SPEC_PENDING_GITHUB_CLOSED[@]}"; do
        IFS=':' read -r story_id platform issue <<< "$item"
        file="$PROJECT_ROOT/specs/requirements/${platform}.md"
        echo "Updating $story_id to Done in $file..."
        sed -i "s/| $story_id |\\(.*\\)Pending/| $story_id |\\1Done/g" "$file"
        sed -i "s/| $story_id |\\(.*\\)🔴/| $story_id |\\1🟢/g" "$file"
    done

    echo ""
    echo -e "${GREEN}Changes applied.${NC}"
else
    echo "Run with --apply to apply these changes."
fi
