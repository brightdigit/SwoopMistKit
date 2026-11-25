# Getting Started with SwoopMistKit

Learn how to build, configure, and run SwoopMistKit.

## Overview

SwoopMistKit's `swoopmist` command-line tool syncs Apple OS, Xcode, Swift, SDK and simulator release data into CloudKit with MistKit. This guide covers building, configuring and running it.

## Prerequisites

- Swift 6.4 (Xcode 27 on macOS)
- macOS 15 or later, or Linux
- A CloudKit container with Server-to-Server authentication configured
- mise (for the lint tools): `brew install mise`, then `mise install`

## Building the Project

Build SwoopMistKit using Swift Package Manager:

```bash
swift build
```

Or use the provided Makefile:

```bash
make build
```

The executable will be available at `.build/debug/swoopmist`.

## Quick Test

Run a dry-run sync to test without uploading to CloudKit:

```bash
.build/debug/swoopmist sync --dry-run --verbose
```

This fetches data from external sources without uploading to CloudKit, and shows verbose output explaining what's happening.

## Next Steps

- <doc:CloudKitSetup> - Configure CloudKit Server-to-Server authentication
- <doc:SyncingData> - Learn how to sync data to CloudKit
- <doc:ExportingData> - Export CloudKit data to JSON

## Development

For development with linting and testing:

```bash
make test     # Run tests
make lint     # Run linting
make xcode    # Generate Xcode project
```

Use Dev Containers for Linux development:

```bash
make docker-test    # Test in Docker
```

See the README for complete development instructions.
