# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Use the following sub-headings when adding changelog entries:

* __Added__ for new features.
* __Changed__ for changes in existing functionality.
* __Deprecated__ for soon-to-be removed features.
* __Removed__ for now removed features.
* __Fixed__ for any bug fixes.
* __Security__ in case of vulnerabilities.

## Unreleased - 2020-12-02

### Added

* New MicroGame `ConnectTheDots` - Still Work-in-progress (b/c you can cheat) - But the basics are there.
  * Works on phone

## Unreleased - 2020-12-24

### Added

* `AudioPlayer` auto-load singleton to manage the main and background audio players
* Several new art assets
* Improvements to the beat-detection algorithm
    * background analysis runs in a thread rather than tieing it to the framerate
    * elliminate several duplicate beats
* Created this changelog to track progress

### Changes

* Code organization, etc.