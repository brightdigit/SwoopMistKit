# CloudKit Integration Patterns

How SwoopMistKit uses MistKit for CloudKit Web Services.

## Overview

SwoopMistKit writes to the public database of a CloudKit container (by default
`iCloud.com.brightdigit.Swoop`) through MistKit, with Server-to-Server authentication, so
no signed-in iCloud user is needed.

## Server-to-Server Authentication

Create a ``SwoopMistKitService`` with the key ID and the ECDSA P-256 private key from the
CloudKit Dashboard, either as PEM text or as a path to the `.pem` file:

```swift
let service = try SwoopMistKitService(
  containerIdentifier: "iCloud.com.brightdigit.Swoop",
  keyID: keyID,
  privateKeyPath: "\(home)/.cloudkit/swoop-private-key.pem",
  environment: .development
)
```

MistKit signs every request and refreshes tokens itself. The database is chosen per call:
SwoopMistKit always uses `.public(.prefers(.serverToServer))`.

## Batch Operations

CloudKit accepts at most 200 operations per request. ``SwoopMistKitService`` chunks the
operations and sends each batch with MistKit's `modifyRecords(_:classification:database:)`,
which returns a structured result:

```swift
let batchResult = try await service.modifyRecords(
  batch,
  classification: classification,
  database: .public(.prefers(.serverToServer))
)
// batchResult.createdCount, .updatedCount, .failedCount, .failed, .totalCount
```

Every operation is a `.forceReplace` with a deterministic record name (built from the
build number), so a repeated sync updates records instead of duplicating them.

## Record Mapping

SwoopKit's records conform to MistKit's `CloudKitRecord` in
`Sources/SwoopMistKit/Extensions/*+CloudKit.swift`:

```swift
protocol CloudKitRecord {
  static var cloudKitRecordType: String { get }
  var recordName: String { get }
  func toCloudKitFields() -> [String: FieldValue]
  static func from(recordInfo: RecordInfo) -> Self?
  static func formatForDisplay(_ recordInfo: RecordInfo) -> String
}
```

```swift
extension RestoreImageRecord: CloudKitRecord {
  public static var cloudKitRecordType: String { "RestoreImage" }

  public func toCloudKitFields() -> [String: FieldValue] {
    [
      "version": .string(.value(version)),
      "buildNumber": .string(.value(buildNumber)),
      "releaseDate": .date(.value(releaseDate)),
      "isPrerelease": FieldValue(booleanValue: isPrerelease),
      // ...
    ]
  }
}
```

## Field Types

Each `FieldValue` kind carries an arity: `.value(x)` for one value, `.list(xs)` for a
list.

| Swift type | CloudKit type | Example |
|------------|---------------|---------|
| `String` | `STRING` | `.string(.value("15.1"))` |
| `Int` | `INT64` | `.int64(.value(fileSize))` |
| `Date` | `TIMESTAMP` | `.date(.value(releaseDate))` |
| `Bool` | `INT64` (0 or 1) | `FieldValue(booleanValue: true)` |
| `URL` | `STRING` | `FieldValue(url: downloadURL)` |
| Reference | `REFERENCE` | `.reference(.value(Reference(recordName: "RestoreImage-23C71")))` |

SwoopMistKit writes no list fields: MistKit can't decode `STRING_LIST` responses yet
(brightdigit/MistKit#509), so a simulator runtime's SDK builds are stored as one
comma-separated `STRING`, `sdkBuildNumbersText`.

CloudKit dates are milliseconds since the epoch; MistKit converts `Date` values both ways.

## Reading Fields

Use MistKit's accessors, which return `nil` for a different kind or a list:

```swift
let version = recordInfo.fields["version"]?.stringValue
let isSigned = recordInfo.fields["isSigned"]?.boolValue
let minimumMacOS = recordInfo.fields["minimumMacOS"]?.referenceValue?.recordName
let downloadURL = recordInfo.fields["downloadURL"]?.urlValue
```

## Upload Order

A reference to a record that doesn't exist yet fails with `VALIDATING_REFERENCE_ERROR`,
so ``SyncEngine`` uploads SwiftVersion and RestoreImage records first, then
XcodeVersion, then SDKVersion (final SDKs before prereleases, which point at them with
`supersededBy`), then SimulatorRuntime.

## Verbose Mode

Pass `--verbose` (or set `SWOOP_SYNC_VERBOSE=true`) to log MistKit calls, batch details
and per-record failures. In code, set `ConsoleOutput.isVerbose = true`.

## Key Types

- ``SwoopMistKitService``: Server-to-Server setup, batching, queries and deletes
- ``SyncEngine``: fetch, transform and upload in order
- ``DataSourcePipeline``: fetching, deduplication and reference resolution
