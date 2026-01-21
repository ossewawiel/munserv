#!/bin/bash
# Create story-specific labels for MunServ
# Usage: ./scripts/create-story-labels.sh
# Requires: gh CLI authenticated

set -e

echo "Creating story-specific labels for MunServ..."

# Check if gh is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "Error: GitHub CLI is not authenticated. Run 'gh auth login' first."
    exit 1
fi

# Get repo from git remote
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")

if [ -z "$REPO" ]; then
    echo "Error: Not in a GitHub repository or remote not configured"
    exit 1
fi

echo "Repository: $REPO"
echo ""

# Function to create or update label
create_label() {
    local name="$1"
    local color="$2"
    local description="$3"

    if gh label view "$name" --repo "$REPO" &>/dev/null; then
        echo "  Exists: $name"
    else
        echo "  Creating: $name"
        gh label create "$name" --repo "$REPO" --color "$color" --description "$description"
    fi
}

# Colors
MOBILE_COLOR="0366D6"  # Blue
WEB_COLOR="008672"     # Green
SHARED_COLOR="6F42C1"  # Purple

# ============================================
# MOBILE STORIES (from specs/requirements/mobile.md)
# ============================================
echo "Mobile stories:"
create_label "story:M1" "$MOBILE_COLOR" "Mobile: Login with email/password"
create_label "story:M2" "$MOBILE_COLOR" "Mobile: Login with PIN/biometric"
create_label "story:M3" "$MOBILE_COLOR" "Mobile: View issues on map"
create_label "story:M4" "$MOBILE_COLOR" "Mobile: View issue list"
create_label "story:M5" "$MOBILE_COLOR" "Mobile: Report new issue"
create_label "story:M6" "$MOBILE_COLOR" "Mobile: View issue details"
create_label "story:M7" "$MOBILE_COLOR" "Mobile: View my reports"

# ============================================
# WEB STORIES (from specs/requirements/web.md)
# ============================================
echo ""
echo "Web stories:"
create_label "story:W1" "$WEB_COLOR" "Web: Login with email/password"
create_label "story:W2" "$WEB_COLOR" "Web: View dashboard"
create_label "story:W3" "$WEB_COLOR" "Web: View issues list"
create_label "story:W4" "$WEB_COLOR" "Web: View issue details"
create_label "story:W5" "$WEB_COLOR" "Web: Change issue state"
create_label "story:W6" "$WEB_COLOR" "Web: View heat report"
create_label "story:W7" "$WEB_COLOR" "Web: View members list"
create_label "story:W8" "$WEB_COLOR" "Web: Register as member"
create_label "story:W9" "$WEB_COLOR" "Web: Approve/reject member"

# ============================================
# SHARED STORIES (placeholder for future)
# ============================================
echo ""
echo "Shared stories (placeholders):"
create_label "story:S1" "$SHARED_COLOR" "Shared: Placeholder for shared story"

echo ""
echo "Story label setup complete!"
echo ""
echo "To add more story labels, edit this script or run:"
echo "  gh label create \"story:M8\" --color \"$MOBILE_COLOR\" --description \"Mobile: Description\""
echo "  gh label create \"story:W10\" --color \"$WEB_COLOR\" --description \"Web: Description\""
