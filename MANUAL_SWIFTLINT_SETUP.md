# Manual SwiftLint Setup Steps

This document outlines the manual steps to integrate SwiftLint into the Xcode project, as doing it programmatically was not feasible in the automated environment.

## Prerequisites

1.  **Install SwiftLint**: If you don't have SwiftLint installed, you can install it using Homebrew (recommended) or by building from source.
    *   **Homebrew**:
        ```bash
        brew install swiftlint
        ```
    *   **From Source**: Refer to the [SwiftLint GitHub repository](https://github.com/realm/SwiftLint) for instructions on building from source.

## Configuration File

1.  **Create `.swiftlint.yml`**: A `.swiftlint.yml` file should already be present at the root of the project with the following content (or your customized rules):

    ```yaml
    disabled_rules:
      - trailing_whitespace
    opt_in_rules:
      - empty_count
      - empty_string
      - explicit_init
      - explicit_top_level_acl
      - explicit_type_interface
      - fatal_error_message
      - force_unwrapping
      - implicitly_unwrapped_optional
      - nimble_operator
      - number_separator
      - object_literal
      - operator_usage_whitespace
      - overridden_super_call
      - private_outlet
      - prohibited_super_call
      - quick_discouraged_call
      - redundant_nil_coalescing
      - single_test_class
      - sorted_imports
      - switch_case_on_newline
      - unneeded_parentheses_in_closure_argument
      - vertical_parameter_alignment_on_call
      - yoda_condition
    line_length: 120
    reporter: "xcode"
    excluded:
      - Pods
      - Carthage
    type_name:
      min_length: 3
      max_length:
        warning: 40
        error: 50
      excluded: iPhone
    identifier_name:
      min_length:
        error: 3
      excluded:
        - id
        - URL
        - GlobalAPIKey
    nesting:
      type_level:
        warning: 2
      statement_level:
        warning: 5
    ```

## Integrate with Xcode Project

1.  **Open your project in Xcode**: Open `businesscard.xcodeproj`.
2.  **Select the Target**: In the Project Navigator, select your main project file (e.g., `businesscard`). Then, select your app target from the list of targets (e.g., `businesscard`).
3.  **Go to "Build Phases"**: Click on the "Build Phases" tab.
4.  **Add a New Run Script Phase**:
    *   Click the "+" button (Add a new build phase).
    *   Select "New Run Script Phase".
5.  **Name the Script**: Rename the newly created "Run Script" phase to something descriptive, like "Run SwiftLint".
6.  **Drag the Script Phase (Optional but Recommended)**: Drag this new phase to run *before* the "Compile Sources" phase. This ensures you see lint warnings and errors before compilation begins.
7.  **Add the Script**: In the shell script text area for your new "Run SwiftLint" phase, add the following script:

    ```bash
    if which swiftlint >/dev/null; then
      swiftlint
    else
      echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
    fi
    ```
    This script checks if SwiftLint is installed and then runs it. If not installed, it prints a warning in Xcode.

8.  **Ensure "Run script only when installing" is UNCHECKED.**

## Verify Integration

1.  **Build your project** (Cmd+B) in Xcode.
2.  If there are any SwiftLint violations, they should now appear as warnings or errors directly within Xcode's Issue Navigator.
3.  You can test it by temporarily adding a violation to one of your Swift files (e.g., a line longer than 120 characters or a force unwrap) and then building again.

By following these steps, SwiftLint will be integrated into your Xcode build process, providing automated linting for your project.
