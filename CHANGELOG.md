# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Support for the ZABORT_STOP_PID environment variable.

- Description of release process in Releasing.md.

### Changed

- Replaced the --signal option with the ZABORT_SIGNAL environment
  variable.

- The stack trace printed by the ZERR trap now shows "TRAPZERR"
  instead of "abort" as the last call.

## [0.1.0] - 2022-03-29

### Added

- Initial public release.

[Unreleased]: https://github.com/paltherr/zabort/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/paltherr/zabort/releases/tag/v0.1.0
