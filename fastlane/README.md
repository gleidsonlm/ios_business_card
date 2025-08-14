fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios increment_build

```sh
[bundle exec] fastlane ios increment_build
```

Increment build number and commit changes

### ios create_release_tag

```sh
[bundle exec] fastlane ios create_release_tag
```

Create git tag for release

### ios deploy_to_testflight

```sh
[bundle exec] fastlane ios deploy_to_testflight
```

Deploy to TestFlight

This lane uploads a protected IPA from Appdome to TestFlight

Options:

  ipa_path: Path to the protected IPA file (required)

  release_notes: Custom release notes (optional)

  groups: TestFlight groups to distribute to (optional, comma-separated)

  skip_waiting_for_build_processing: Skip waiting for build processing (default: false)

  increment_build: Increment build number before upload (default: true)

### ios validate_testflight_setup

```sh
[bundle exec] fastlane ios validate_testflight_setup
```

Validate TestFlight deployment prerequisites

### ios test_deployment

```sh
[bundle exec] fastlane ios test_deployment
```

Test deployment with a sample IPA path (dry run)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
