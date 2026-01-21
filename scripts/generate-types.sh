#!/bin/bash
# Generate platform types from specs/contracts/types.md
# Usage: ./scripts/generate-types.sh [--dry-run] [--type TYPE_NAME] [--platform PLATFORM]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Defaults
DRY_RUN=false
TYPE_NAME=""
PLATFORM="all"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --type)
            TYPE_NAME="$2"
            shift 2
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Paths
TYPES_SPEC="$PROJECT_ROOT/specs/contracts/types.md"
KOTLIN_DIR="$PROJECT_ROOT/backend/src/main/kotlin/com/munserv/shared/enums"
TS_DIR="$PROJECT_ROOT/web/src/types"
DART_DIR="$PROJECT_ROOT/mobile/lib/shared/enums"

echo "=========================================="
echo "Type Generation"
echo "=========================================="
echo ""
echo "Source: $TYPES_SPEC"
echo "Dry Run: $DRY_RUN"
echo "Type Filter: ${TYPE_NAME:-all}"
echo "Platform: $PLATFORM"
echo ""

# Check source file exists
if [ ! -f "$TYPES_SPEC" ]; then
    echo -e "${YELLOW}Warning: $TYPES_SPEC not found${NC}"
    echo "Creating template..."

    if [ "$DRY_RUN" = "false" ]; then
        mkdir -p "$(dirname "$TYPES_SPEC")"
        cat > "$TYPES_SPEC" << 'EOF'
# Shared Types

This file is the single source of truth for type definitions across platforms.

## Annotation Reference

- `@enum` - This is an enumeration type
- `@generate(kotlin, typescript, dart)` - Generate for these platforms
- `@serialization(snake_case)` - Use snake_case for JSON serialization

---

## GroundAdminStatus
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description |
|-------|-------------|
| pending | Awaiting approval |
| approved | Active ground admin |
| rejected | Application denied |
| revoked | Access removed |

## IssueState
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description |
|-------|-------------|
| reported | Initial state |
| confirmed | Verified by admin |
| in_progress | Being worked on |
| fixed | Issue resolved |
| wont_fix | Closed without fix |

## IssueType
@enum @generate(kotlin, typescript, dart)
@serialization(snake_case)

| Value | Description |
|-------|-------------|
| pothole | Road damage |
| streetlight | Lighting issue |
| water_leak | Water infrastructure |
| garbage | Waste management |
| other | Miscellaneous |
EOF
        echo -e "${GREEN}Created template at $TYPES_SPEC${NC}"
    else
        echo "Would create template at $TYPES_SPEC"
    fi
    echo ""
fi

# Parse types from spec
echo "Parsing type definitions..."
echo ""

# Simple parser - extracts enum blocks
parse_enum() {
    local name="$1"
    local content=""
    local in_enum=false
    local platforms=""
    local serialization="snake_case"

    while IFS= read -r line; do
        if [[ "$line" =~ ^##[[:space:]]+$name[[:space:]]*$ ]]; then
            in_enum=true
            continue
        fi

        if [ "$in_enum" = "true" ]; then
            # Check for next section
            if [[ "$line" =~ ^##[[:space:]] ]] && [[ ! "$line" =~ ^##[[:space:]]+$name ]]; then
                break
            fi

            # Extract annotations
            if [[ "$line" =~ @generate\(([^)]+)\) ]]; then
                platforms="${BASH_REMATCH[1]}"
            fi
            if [[ "$line" =~ @serialization\(([^)]+)\) ]]; then
                serialization="${BASH_REMATCH[1]}"
            fi

            # Extract table values (| value | description |)
            if [[ "$line" =~ ^\|[[:space:]]*([a-z_]+)[[:space:]]*\| ]]; then
                local value="${BASH_REMATCH[1]}"
                if [ "$value" != "Value" ] && [ "$value" != "---" ] && [ -n "$value" ]; then
                    content="${content}${value}\n"
                fi
            fi
        fi
    done < "$TYPES_SPEC"

    echo "PLATFORMS=$platforms"
    echo "SERIALIZATION=$serialization"
    echo "VALUES=$(echo -e "$content" | tr '\n' ',')"
}

# Generate Kotlin enum
generate_kotlin() {
    local name="$1"
    local values="$2"
    local output_file="$KOTLIN_DIR/$name.kt"

    echo -e "${BLUE}Generating Kotlin:${NC} $output_file"

    local content="package com.munserv.shared.enums

import com.fasterxml.jackson.annotation.JsonValue

/**
 * $name enum - generated from specs/contracts/types.md
 * DO NOT EDIT MANUALLY
 */
enum class $name(
    @JsonValue val value: String
) {
"

    IFS=',' read -ra vals <<< "$values"
    for i in "${!vals[@]}"; do
        local val="${vals[$i]}"
        [ -z "$val" ] && continue
        local const_name=$(echo "$val" | tr '[:lower:]' '[:upper:]')
        local comma=","
        if [ $i -eq $((${#vals[@]} - 2)) ]; then
            comma=""
        fi
        content="${content}    ${const_name}(\"${val}\")${comma}
"
    done

    content="${content}    ;

    companion object {
        fun fromValue(value: String): $name? =
            entries.find { it.value == value }
    }
}
"

    if [ "$DRY_RUN" = "true" ]; then
        echo "Would write to: $output_file"
        echo "---"
        echo "$content"
        echo "---"
    else
        mkdir -p "$(dirname "$output_file")"
        echo "$content" > "$output_file"
        echo -e "${GREEN}Written:${NC} $output_file"
    fi
}

# Generate TypeScript type
generate_typescript() {
    local name="$1"
    local values="$2"
    local kebab_name=$(echo "$name" | sed 's/\([A-Z]\)/-\L\1/g' | sed 's/^-//')
    local output_file="$TS_DIR/$kebab_name.ts"

    echo -e "${BLUE}Generating TypeScript:${NC} $output_file"

    local content="/**
 * $name type - generated from specs/contracts/types.md
 * DO NOT EDIT MANUALLY
 */

export const $name = {
"

    IFS=',' read -ra vals <<< "$values"
    for val in "${vals[@]}"; do
        [ -z "$val" ] && continue
        local const_name=$(echo "$val" | tr '[:lower:]' '[:upper:]')
        content="${content}  ${const_name}: '${val}',
"
    done

    local camel_name=$(echo "$name" | sed 's/^\(.\)/\L\1/')

    content="${content}} as const;

export type $name = typeof $name[keyof typeof $name];

export const ${camel_name}Values = Object.values($name);

export function is$name(value: unknown): value is $name {
  return ${camel_name}Values.includes(value as $name);
}
"

    if [ "$DRY_RUN" = "true" ]; then
        echo "Would write to: $output_file"
        echo "---"
        echo "$content"
        echo "---"
    else
        mkdir -p "$(dirname "$output_file")"
        echo "$content" > "$output_file"
        echo -e "${GREEN}Written:${NC} $output_file"
    fi
}

# Generate Dart enum
generate_dart() {
    local name="$1"
    local values="$2"
    local snake_name=$(echo "$name" | sed 's/\([A-Z]\)/_\L\1/g' | sed 's/^_//')
    local output_file="$DART_DIR/$snake_name.dart"

    echo -e "${BLUE}Generating Dart:${NC} $output_file"

    local content="import 'package:json_annotation/json_annotation.dart';

/// $name enum - generated from specs/contracts/types.md
/// DO NOT EDIT MANUALLY
enum $name {
"

    IFS=',' read -ra vals <<< "$values"
    for val in "${vals[@]}"; do
        [ -z "$val" ] && continue
        # Convert to camelCase
        local camel_val=$(echo "$val" | sed -r 's/_([a-z])/\U\1/g')
        content="${content}  @JsonValue('${val}')
  ${camel_val},
"
    done

    content="${content}}
"

    if [ "$DRY_RUN" = "true" ]; then
        echo "Would write to: $output_file"
        echo "---"
        echo "$content"
        echo "---"
    else
        mkdir -p "$(dirname "$output_file")"
        echo "$content" > "$output_file"
        echo -e "${GREEN}Written:${NC} $output_file"
    fi
}

# Find and process enums
echo "Processing enums..."
echo ""

# Extract enum names from spec
ENUM_NAMES=$(grep -E '^## [A-Z]' "$TYPES_SPEC" 2>/dev/null | sed 's/## //' | tr -d '\r' || true)

for enum_name in $ENUM_NAMES; do
    # Skip if filtering by type
    if [ -n "$TYPE_NAME" ] && [ "$enum_name" != "$TYPE_NAME" ]; then
        continue
    fi

    echo "=========================================="
    echo "Processing: $enum_name"
    echo "=========================================="

    # Parse enum
    eval "$(parse_enum "$enum_name")"

    # Clean up values
    VALUES=$(echo "$VALUES" | sed 's/,$//')

    echo "Platforms: $PLATFORMS"
    echo "Values: $VALUES"
    echo ""

    # Generate for each platform
    if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "kotlin" ]; then
        if [[ "$PLATFORMS" == *"kotlin"* ]]; then
            generate_kotlin "$enum_name" "$VALUES"
        fi
    fi

    if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "typescript" ]; then
        if [[ "$PLATFORMS" == *"typescript"* ]]; then
            generate_typescript "$enum_name" "$VALUES"
        fi
    fi

    if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "dart" ]; then
        if [[ "$PLATFORMS" == *"dart"* ]]; then
            generate_dart "$enum_name" "$VALUES"
        fi
    fi

    echo ""
done

echo "=========================================="
echo "Complete"
echo "=========================================="

if [ "$DRY_RUN" = "true" ]; then
    echo -e "${YELLOW}Dry run complete. No files were written.${NC}"
    echo "Run without --dry-run to generate files."
else
    echo -e "${GREEN}Type generation complete.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review generated files"
    echo "2. Run validation: ./scripts/validate-enum-sync.sh"
    echo "3. Run tests for each platform"
fi
