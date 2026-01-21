#!/bin/bash
# Validate enum synchronization across platforms
# Usage: ./scripts/validate-enum-sync.sh [enum_name]
# If no enum_name provided, validates all enums

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Paths
KOTLIN_ENUMS="$PROJECT_ROOT/backend/src/main/kotlin/com/munserv/shared/enums"
TS_TYPES="$PROJECT_ROOT/web/src/types"
DART_MODELS="$PROJECT_ROOT/mobile/lib/shared/models"

# Track drift
DRIFT_FOUND=false
DRIFT_REPORT=""

echo "=========================================="
echo "Enum Synchronization Validation"
echo "=========================================="
echo ""

# Function to extract Kotlin enum values
extract_kotlin_values() {
    local file="$1"
    grep -oP '(?<=\s)[A-Z_]+(?=\(|,|\s*;)' "$file" 2>/dev/null | sort | uniq || true
}

# Function to extract Kotlin serialized values
extract_kotlin_serialized() {
    local file="$1"
    grep -oP '(?<=")[a-z_]+(?=")' "$file" 2>/dev/null | sort | uniq || true
}

# Function to extract TypeScript values
extract_ts_values() {
    local file="$1"
    grep -oP "(?<=: ')[a-z_]+(?=')" "$file" 2>/dev/null | sort | uniq || true
}

# Function to extract Dart enum values
extract_dart_values() {
    local file="$1"
    grep -oP "(?<=@JsonValue\(')[a-z_]+(?='\))" "$file" 2>/dev/null | sort | uniq || true
}

# Function to compare values
compare_values() {
    local enum_name="$1"
    local kotlin_vals="$2"
    local ts_vals="$3"
    local dart_vals="$4"

    local has_diff=false

    # Check Kotlin vs TypeScript
    if [ -n "$kotlin_vals" ] && [ -n "$ts_vals" ]; then
        local kt_only=$(comm -23 <(echo "$kotlin_vals") <(echo "$ts_vals"))
        local ts_only=$(comm -13 <(echo "$kotlin_vals") <(echo "$ts_vals"))

        if [ -n "$kt_only" ]; then
            echo -e "${RED}  Kotlin only:${NC} $kt_only"
            has_diff=true
        fi
        if [ -n "$ts_only" ]; then
            echo -e "${RED}  TypeScript only:${NC} $ts_only"
            has_diff=true
        fi
    fi

    # Check Kotlin vs Dart
    if [ -n "$kotlin_vals" ] && [ -n "$dart_vals" ]; then
        local kt_only=$(comm -23 <(echo "$kotlin_vals") <(echo "$dart_vals"))
        local dart_only=$(comm -13 <(echo "$kotlin_vals") <(echo "$dart_vals"))

        if [ -n "$kt_only" ]; then
            echo -e "${RED}  Kotlin only (vs Dart):${NC} $kt_only"
            has_diff=true
        fi
        if [ -n "$dart_only" ]; then
            echo -e "${RED}  Dart only:${NC} $dart_only"
            has_diff=true
        fi
    fi

    if [ "$has_diff" = "true" ]; then
        DRIFT_FOUND=true
        DRIFT_REPORT="${DRIFT_REPORT}\n- ${enum_name}: Values differ across platforms"
    fi
}

# Validate a single enum
validate_enum() {
    local enum_name="$1"
    local kotlin_file=""
    local ts_file=""
    local dart_file=""

    echo "Checking: $enum_name"

    # Find files
    kotlin_file=$(find "$KOTLIN_ENUMS" -name "${enum_name}.kt" 2>/dev/null | head -1)
    ts_file=$(find "$TS_TYPES" -name "*.ts" -exec grep -l "export const ${enum_name}" {} \; 2>/dev/null | head -1)
    dart_file=$(find "$DART_MODELS" -name "*.dart" ! -name "*.freezed.dart" ! -name "*.g.dart" -exec grep -l "enum ${enum_name}" {} \; 2>/dev/null | head -1)

    # Extract values
    local kotlin_vals=""
    local ts_vals=""
    local dart_vals=""

    if [ -n "$kotlin_file" ]; then
        kotlin_vals=$(extract_kotlin_serialized "$kotlin_file")
        echo -e "  ${GREEN}Kotlin:${NC} $kotlin_file"
        echo "    Values: $kotlin_vals"
    else
        echo -e "  ${YELLOW}Kotlin:${NC} Not found"
    fi

    if [ -n "$ts_file" ]; then
        ts_vals=$(extract_ts_values "$ts_file")
        echo -e "  ${GREEN}TypeScript:${NC} $ts_file"
        echo "    Values: $ts_vals"
    else
        echo -e "  ${YELLOW}TypeScript:${NC} Not found"
    fi

    if [ -n "$dart_file" ]; then
        dart_vals=$(extract_dart_values "$dart_file")
        echo -e "  ${GREEN}Dart:${NC} $dart_file"
        echo "    Values: $dart_vals"
    else
        echo -e "  ${YELLOW}Dart:${NC} Not found"
    fi

    # Compare if we have at least 2 platforms
    local platforms_found=0
    [ -n "$kotlin_vals" ] && platforms_found=$((platforms_found + 1))
    [ -n "$ts_vals" ] && platforms_found=$((platforms_found + 1))
    [ -n "$dart_vals" ] && platforms_found=$((platforms_found + 1))

    if [ "$platforms_found" -ge 2 ]; then
        compare_values "$enum_name" "$kotlin_vals" "$ts_vals" "$dart_vals"
    fi

    echo ""
}

# Main logic
if [ -n "$1" ]; then
    # Validate specific enum
    validate_enum "$1"
else
    # Validate all Kotlin enums
    echo "Finding all enums in backend..."
    echo ""

    for kotlin_file in "$KOTLIN_ENUMS"/*.kt; do
        [ -f "$kotlin_file" ] || continue
        enum_name=$(basename "$kotlin_file" .kt)
        validate_enum "$enum_name"
    done
fi

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="

if [ "$DRIFT_FOUND" = "true" ]; then
    echo -e "${RED}DRIFT DETECTED${NC}"
    echo -e "$DRIFT_REPORT"
    echo ""
    echo "Run '/generate-types' to regenerate types from spec."
    exit 1
else
    echo -e "${GREEN}All enums synchronized${NC}"
    exit 0
fi
