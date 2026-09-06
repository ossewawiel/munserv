#!/bin/bash
# Setup GitHub labels for MunServ project
# Usage: ./scripts/setup-github-labels.sh
# Requires: gh CLI authenticated

set -e

echo "Setting up GitHub labels for MunServ..."

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

# Function to create or update label
create_label() {
    local name="$1"
    local color="$2"
    local description="$3"

    # Check if label exists
    if gh label view "$name" --repo "$REPO" &>/dev/null; then
        echo "Updating label: $name"
        gh label edit "$name" --repo "$REPO" --color "$color" --description "$description"
    else
        echo "Creating label: $name"
        gh label create "$name" --repo "$REPO" --color "$color" --description "$description"
    fi
}

# ============================================
# TYPE LABELS
# ============================================
create_label "type:feature" "0E8A16" "New functionality or user story"
create_label "type:bug" "D73A4A" "Something isn't working correctly"
create_label "type:docs" "0075CA" "Documentation improvements"
create_label "type:standards" "FBCA04" "Coding standards or architecture violation"
create_label "type:tech-debt" "5319E7" "Technical debt to address"
create_label "type:chore" "EDEDED" "Maintenance tasks (dependencies, CI, etc.)"

# ============================================
# PLATFORM LABELS
# ============================================
create_label "platform:backend" "7057FF" "Affects Kotlin/Spring Boot backend"
create_label "platform:web" "008672" "Affects React/TypeScript web admin"
create_label "platform:mobile" "0366D6" "Affects Flutter mobile app"
create_label "platform:database" "B60205" "Affects database schema or migrations"
create_label "platform:infra" "6F42C1" "Affects infrastructure or DevOps"

# ============================================
# STATUS LABELS
# ============================================
create_label "status:triage" "FFFFFF" "Needs review and prioritization"
create_label "status:ready" "C2E0C6" "Ready to be picked up"
create_label "status:in-progress" "FEF2C0" "Currently being worked on"
create_label "status:blocked" "F9D0C4" "Blocked by dependency or question"
create_label "status:review" "BFDADC" "PR open, awaiting review"
create_label "status:done" "0E8A16" "Completed and merged"

# ============================================
# PRIORITY LABELS
# ============================================
create_label "priority:critical" "B60205" "Blocking release or other work"
create_label "priority:high" "D93F0B" "Must have for next release"
create_label "priority:medium" "FBCA04" "Should have"
create_label "priority:low" "0E8A16" "Nice to have"

# ============================================
# SOURCE LABELS
# ============================================
create_label "source:agent-requested" "1D76DB" "Created by Claude agent"
create_label "source:user-requested" "BFD4F2" "Created by human user"
create_label "source:spec-derived" "D4C5F9" "Derived from spec documents"
create_label "source:automated" "EDEDED" "Created by automated workflow"
create_label "source:eyeball" "FBCA04" "Filed from a manual eyeball session"

# ============================================
# EYEBALL LABELS
# ============================================
create_label "eyeball:pass" "0E8A16" "Eyeball: every check passed"
create_label "eyeball:fail" "D73A4A" "Eyeball: at least one check failed"

echo ""
echo "Label setup complete!"
echo "To create story-specific labels, run: ./scripts/create-story-labels.sh"
