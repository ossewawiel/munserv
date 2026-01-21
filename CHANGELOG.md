# Changelog

All notable changes to MunServ will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub-centric documentation synchronization system
  - Issue templates for features, bugs, and standards violations
  - Label taxonomy for tracking work across platforms
  - GitHub Actions workflows for spec validation and auto-sync
  - Changelog generation using git-cliff
- New Claude skills for GitHub integration
  - `/create-issue` - Create GitHub issues from conversation context
  - `/sync-github` - Bidirectional sync between specs and GitHub
  - `/close-handoff` - Mark handoff documents resolved
  - `/generate-types` - Generate platform types from specs
- Type generation system from specs/contracts/types.md
  - Kotlin enum generation
  - TypeScript type generation
  - Dart enum generation
- Standards registry for tracking coding standards compliance
- Validation scripts for enum synchronization

### Changed
- Updated `/add-story` skill with GitHub issue creation step
- Updated `/plan-feature` skill with milestone and issue creation
- Added Issue column to mobile and web requirements tables
- Added generation annotations to enum definitions in types.md

---

*Generated with [git-cliff](https://git-cliff.org/) - see `.github/cliff.toml` for configuration*
