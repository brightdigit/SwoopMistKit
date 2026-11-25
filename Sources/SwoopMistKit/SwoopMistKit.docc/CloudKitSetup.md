# CloudKit Server-to-Server Authentication Setup

Configure CloudKit credentials and schema for SwoopMistKit.

## Overview

SwoopMistKit uses CloudKit's Server-to-Server authentication, which allows command-line tools and servers to access CloudKit without user credentials. This guide explains how to set up the required authentication keys and CloudKit schema.

## Quick Start

If you just want to get started quickly:

1. Generate an S2S key pair and register it in CloudKit Dashboard
2. Set environment variables for the key ID and private key file
3. Run the automated schema setup script
4. Start syncing data

For detailed instructions, continue reading below.

---

## Part 1: Server-to-Server Authentication

### What is Server-to-Server Authentication?

Server-to-Server (S2S) authentication allows backend services, scripts, and CLI tools to access CloudKit **without requiring a signed-in iCloud user**. This is essential for:

- Automated data syncing from external APIs
- Scheduled batch operations
- Server-side data processing
- Command-line tools that manage CloudKit data

### Step 1: Generate the Key Pair

Open Terminal and generate an ECDSA P-256 key pair using OpenSSL:

```bash
# Generate private key
openssl ecparam -name prime256v1 -genkey -noout -out eckey.pem

# Extract public key
openssl ec -in eckey.pem -pubout -out eckey_pub.pem
```

**Important:** Keep `eckey.pem` (private key) **secure and confidential**. Never commit it to version control.

### Step 2: Register Key in CloudKit Dashboard

1. **Navigate to CloudKit Dashboard**
   - Go to [CloudKit Dashboard](https://icloud.developer.apple.com/)
   - Select your Team
   - Select your Container (or create one if needed)

2. **Navigate to Server-to-Server Keys**
   - In the left sidebar, under "Settings"
   - Click "Server-to-Server Keys"

3. **Create New Server-to-Server Key**
   - Click the "+" button to create a new key
   - **Name:** Give it a descriptive name (e.g., "SwoopMistKit Development Key")
   - **Public Key:** Paste the contents of `eckey_pub.pem`

4. **Save and Record Key ID**
   - After saving, CloudKit will display a **Key ID** (long hexadecimal string)
   - **Copy this Key ID** - you'll need it for authentication
   - Example: `3e76ace055d2e3881a4e9c862dd1119ea85717bd743c1c8c15d95b2280cd93ab`

### Step 3: Secure Key Storage

Store your private key securely:

```bash
# Create secure directory
mkdir -p ~/.cloudkit
chmod 700 ~/.cloudkit

# Move private key to secure location
mv eckey.pem ~/.cloudkit/swoop-private-key.pem
chmod 600 ~/.cloudkit/swoop-private-key.pem
```

### Step 4: Configure Environment Variables

Set the following environment variables:

```bash
export CLOUDKIT_KEY_ID="your-key-id-here"
export CLOUDKIT_PRIVATE_KEY_PATH="$HOME/.cloudkit/swoop-private-key.pem"
export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Swoop"  # Optional; the default
```

Add these to your shell profile (~/.zshrc or ~/.bashrc) for persistence:

```bash
# Add to ~/.zshrc
echo 'export CLOUDKIT_KEY_ID="your-key-id-here"' >> ~/.zshrc
echo 'export CLOUDKIT_PRIVATE_KEY_PATH="$HOME/.cloudkit/swoop-private-key.pem"' >> ~/.zshrc
echo 'export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Swoop"' >> ~/.zshrc
```

### Step 5: Verify Setup

Test your configuration with a status check:

```bash
swoopmist status
```

This should connect to CloudKit and display your container configuration.

---

## Part 2: CloudKit Schema Setup

SwoopMistKit requires specific record types in your CloudKit public database. You can set up the schema automatically or manually.

### Option 1: Automated Setup (Recommended)

Use the provided script to automatically import the schema:

```bash
# Set required environment variables
export CLOUDKIT_CONTAINER_ID="iCloud.com.brightdigit.Swoop"
export CLOUDKIT_TEAM_ID="YOUR_TEAM_ID"
export CLOUDKIT_ENVIRONMENT="development"  # or "production"

# Run the setup script
./Scripts/setup-cloudkit-schema.sh
```

**Prerequisites:**
- Xcode Command Line Tools installed
- CloudKit Management Token (the script will guide you through obtaining one)
- Your Team ID (10-character identifier from Apple Developer account)

### Option 2: Manual Schema Creation

If you prefer manual setup, follow these steps:

#### Get a Management Token

Management tokens allow `cktool` to modify your CloudKit schema:

1. Open [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your container
3. Click your profile icon (top right)
4. Select "API Access" → "CloudKit Web Services"
5. Click "Create Management Token"
6. Give it a name: "SwoopMistKit Schema Management"
7. **Copy the token** (you won't see it again!)
8. Save it using `cktool`:

```bash
xcrun cktool save-token
# Paste token when prompted
```

#### Import the Schema

```bash
xcrun cktool import-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.brightdigit.Swoop \
  --environment development \
  --file schema.ckdb
```

#### Verify Schema Import

```bash
xcrun cktool export-schema \
  --team-id YOUR_TEAM_ID \
  --container-id iCloud.com.brightdigit.Swoop \
  --environment development \
  > current-schema.ckdb

# Check the permissions
cat current-schema.ckdb | grep -A 2 "GRANT"
```

You should see the grants from `schema.ckdb`: `READ, CREATE, WRITE` for `_creator` on every
record type; "Critical Schema Permissions" below covers the rest.

---

## Required Record Types

SwoopMistKit requires these record types in your CloudKit public database:

### RestoreImage

macOS restore images for virtualization:

| Field | Type | Description |
|-------|------|-------------|
| `version` | STRING | macOS version (e.g., "15.0") |
| `buildNumber` | STRING | Build number (e.g., "24A335") - unique key |
| `releaseDate` | TIMESTAMP | Release date |
| `downloadURL` | STRING | Download URL for IPSW file |
| `fileSize` | INT64 | File size in bytes |
| `sha256Hash` | STRING | SHA-256 checksum |
| `sha1Hash` | STRING | SHA-1 checksum |
| `isSigned` | INT64 | Signing status (0=no, 1=yes) |
| `isPrerelease` | INT64 | Prerelease status (0=no, 1=yes) |
| `source` | STRING | Data source (e.g., "ipsw.me") |
| `notes` | STRING | Optional metadata |
| `sourceUpdatedAt` | TIMESTAMP | Last update from source |

### XcodeVersion

Xcode releases and build numbers:

| Field | Type | Description |
|-------|------|-------------|
| `version` | STRING | Xcode version (e.g., "16.0") |
| `buildNumber` | STRING | Build number (e.g., "16A242") - unique key |
| `releaseDate` | TIMESTAMP | Release date |
| `isPrerelease` | INT64 | Prerelease status (0=no, 1=yes) |
| `prereleaseLabel` | STRING | "Beta 3", "RC 1", … (optional) |
| `downloadURL` | STRING | Download URL (optional) |
| `fileSize` | INT64 | File size in bytes (optional) |
| `minimumMacOS` | REFERENCE | Reference to a RestoreImage record |
| `includedSwiftVersion` | REFERENCE | Reference to a SwiftVersion record |
| `sdkVersions` | STRING | The SDKs Xcode ships, as text |
| `notes` | STRING | Optional metadata |

### SwiftVersion

Swift compiler versions:

| Field | Type | Description |
|-------|------|-------------|
| `version` | STRING | Swift version (e.g., "6.0.2") - unique key |
| `releaseDate` | TIMESTAMP | Release date |
| `isPrerelease` | INT64 | Prerelease status (0=no, 1=yes) |
| `downloadURL` | STRING | Download URL (optional) |
| `notes` | STRING | Optional metadata |

### SDKVersion

One record per platform and SDK build:

| Field | Type | Description |
|-------|------|-------------|
| `platform` | STRING | "iOS", "macOS", … |
| `version` | STRING | SDK version |
| `buildNumber` | STRING | SDK build number |
| `isPrerelease` | INT64 | Prerelease status (0=no, 1=yes) |
| `prereleaseLabel` | STRING | "Beta 3", "RC 1", … (optional) |
| `releaseDate` | TIMESTAMP | Release date (UTC day) |
| `xcodeVersion` | REFERENCE | The Xcode that ships the SDK |
| `supersededBy` | REFERENCE | For a beta, the final SDK of the same version |
| `supersededAt` | TIMESTAMP | When the final SDK shipped |

### SimulatorRuntime

One record per platform and runtime build, from Apple's simulator index:

| Field | Type | Description |
|-------|------|-------------|
| `platform` | STRING | "iOS", "watchOS", … |
| `version` | STRING | Runtime version |
| `buildNumber` | STRING | Runtime build number |
| `isPrerelease` | INT64 | Prerelease status (0=no, 1=yes) |
| `releaseLabel` | STRING | "Beta N", "RC N" or "Final" |
| `sdkBuildNumbersText` | STRING | Comma-separated SDK builds the runtime maps to |

### DataSourceMetadata

Fetch metadata and throttling information:

| Field | Type | Description |
|-------|------|-------------|
| `sourceName` | STRING | Data source name |
| `recordTypeName` | STRING | Record type being tracked |
| `lastFetchedAt` | TIMESTAMP | Last fetch time |
| `sourceUpdatedAt` | TIMESTAMP | Source last updated |
| `recordCount` | INT64 | Number of records fetched |
| `fetchDurationSeconds` | DOUBLE | Fetch duration |
| `lastError` | STRING | Last error message (optional) |

---

## Critical Schema Permissions

A Server-to-Server key creates records as `_creator` but also needs `CREATE` on
`_icloud`; granting only one role results in `ACCESS_DENIED` errors. `schema.ckdb` uses
two patterns:

```text
// RestoreImage, SwiftVersion, DataSourceMetadata
GRANT READ, CREATE, WRITE TO "_creator",
GRANT READ, CREATE, WRITE TO "_icloud",
GRANT READ TO "_world"

// XcodeVersion, SDKVersion, SimulatorRuntime
GRANT READ, CREATE, WRITE TO "_creator",
GRANT READ, CREATE TO "_icloud"
```

The second pattern has no `_world` grant and no `_icloud` write: simulator managers read
those records with a signed-in iCloud account, and only the S2S sync writes them.

---

## Troubleshooting

### "Authentication failed" (HTTP 401)

**Cause:** Invalid or revoked Key ID

**Solution:**
1. Generate a new S2S key in CloudKit Dashboard
2. Update `CLOUDKIT_KEY_ID` environment variable
3. Verify private key file is correct

### "ACCESS_DENIED - CREATE operation not permitted"

**Cause:** Schema permissions don't grant CREATE to both `_creator` and `_icloud`

**Solution:**
1. Export current schema: `xcrun cktool export-schema ...`
2. Verify permissions show both `_creator` and `_icloud`
3. If missing, update schema file and re-import

### "Private key file not found"

**Cause:** File doesn't exist at specified path

**Solution:**
- Use absolute path: `$HOME/.cloudkit/swoop-private-key.pem`
- Verify file exists: `ls -la $CLOUDKIT_PRIVATE_KEY_PATH`
- Check file permissions: `chmod 600 $CLOUDKIT_PRIVATE_KEY_PATH`

### "Schema validation failed: Was expecting DEFINE"

**Cause:** Schema file missing `DEFINE SCHEMA` header

**Solution:**
Add this line at the top of your `schema.ckdb` file:
```text
DEFINE SCHEMA
```

### "Container not found"

**Cause:** Container ID doesn't match CloudKit Dashboard

**Solution:**
1. Verify container ID in CloudKit Dashboard
2. Check `CLOUDKIT_CONTAINER_ID` environment variable
3. Ensure Team ID is correct

---

## Security Notes

**Never commit** your private key (.pem file) to version control:

```gitignore
# .gitignore
*.pem
*.p8
.env
.cloudkit/
```

**Best practices:**
- Store credentials in `~/.cloudkit/` with restrictive permissions (600)
- Use environment variables, not hardcoded values
- Generate separate keys for development and production
- Rotate keys periodically (every 6-12 months)

---

## Next Steps

After setting up authentication and schema:

- <doc:SyncingData> - Start syncing data to CloudKit
- <doc:DataFlow> - Understand how data flows through SwoopMistKit
- <doc:ExportingData> - Export CloudKit data to JSON

## Additional Resources

- [CloudKit Web Services Documentation](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/)
- [Server-to-Server Keys Guide](https://developer.apple.com/documentation/cloudkit)
- [cktool Reference](https://keith.github.io/xcode-man-pages/cktool.1.html)
- [CloudKit Dashboard](https://icloud.developer.apple.com/)
