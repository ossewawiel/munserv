# Investigation: Coding standards check on GitHub

**Issue:** #14
**Date:** 2026-01-21
**Platforms:** GitHub Actions (Infrastructure)

## Problem Statement

The GitHub Actions `standards-check.yml` workflow fails with a JavaScript syntax error:
```
SyntaxError: Unexpected token ':'
    at new AsyncFunction (<anonymous>)
    at callAsyncFunction (actions/github-script/v7/dist/index.js:36187:16)
```

## Investigation Steps

1. Fetched issue details from GitHub - confirmed error in `actions/github-script@v7`
2. Located workflow file: `.github/workflows/standards-check.yml`
3. Analyzed the `github-script` step (lines 113-138)

## Root Cause

The issue is in the `github-script` step at lines 117-138. The workflow uses `${{ }}` GitHub Actions expression syntax inside a JavaScript template literal:

```yaml
- name: Comment on PR with violations
  uses: actions/github-script@v7
  with:
    script: |
      const violations = `${{ steps.forbidden-check.outputs.violations }}`;
```

**Problems:**

1. **Expression injection vulnerability**: The `${{ steps.forbidden-check.outputs.violations }}` is interpolated at YAML parsing time, BEFORE the JavaScript runs. If the violations output contains special characters like `:`, backticks, `${}`, or other JavaScript syntax characters, it will break the JavaScript parser.

2. **Specific failure scenario**: The violations output contains markdown code blocks with file paths like `/path/to/file.kt:123`, where the `:` is being interpreted as JavaScript object syntax inside the template literal.

3. **Example of what happens**:
   - Shell outputs: `backend/src/Foo.kt:42: some violation`
   - YAML interpolates it directly into JS: ``const violations = `backend/src/Foo.kt:42: some violation`;``
   - JavaScript parser sees the `:` and tries to parse it as part of an object literal or ternary operator

## Affected Components

### Infrastructure (.github/workflows)
- `.github/workflows/standards-check.yml` - lines 113-138

## Fix Approach

Replace the direct `${{ }}` interpolation with a safer method using `core.getInput()` or by properly escaping the output. The recommended fix is to:

1. Use `actions/github-script@v7`'s built-in input handling
2. Pass the violations as an environment variable and access it via `process.env`
3. Use JSON encoding for safe transfer of multiline/special character content

### Recommended Solution

```yaml
- name: Comment on PR with violations
  if: steps.forbidden-check.outputs.violation_count != '0'
  uses: actions/github-script@v7
  env:
    VIOLATIONS: ${{ steps.forbidden-check.outputs.violations }}
  with:
    script: |
      const violations = process.env.VIOLATIONS || '';
      const body = `## Standards Check Warning

      This PR contains potential coding standards violations. Please review:

      ${violations}

      ### Standards Reference
      - CLAUDE.md#critical-rules
      - CLAUDE.md#forbidden

      ---
      *This is a warning only - the PR is not blocked. Please review and fix if appropriate.*
      `;

      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: body
      });
```

By passing the value through `env:` and accessing via `process.env`, the value is properly escaped and won't be interpreted as JavaScript code.
