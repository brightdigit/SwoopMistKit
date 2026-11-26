# CI runner images

- Apple lanes run on the `xcode-27` (preview) runner label with `/Applications/Xcode_27.2.app`. Its 27.2 simulators are named iPhone 18 Pro, Apple Watch Ultra 4 (49mm), Apple TV 4K (4th generation) and Apple Vision Pro; a wrong name fails the simulator boot.
- A simulator job can fail with "test runner hung before establishing connection". That's a runner flake: re-run the failed job once before investigating.
- Lint runs on `ubuntu-24.04`, not `ubuntu-latest` (26.04 lacks `libxml2.so.2` for SwiftLint).
- Linux lanes use the release `swift:6.4-<os>` images.
