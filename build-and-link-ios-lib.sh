#!/bin/sh

# If you are going to edit this scrip[t, please follow the color codes used in yioour echo statements:
# 
# Green (\033[0;32m): Success or completion messages.
# Yellow (\033[0;33m): Warning or process-start messages.
# Blue (\033[0;34m): Information or ongoing process messages.
# Red (\033[0;31m): Error messages.

workingdir="$(pwd)"

function cleanup() {
    echo "\033[0;32mcleaning up...\033[0m" # Green color for cleanup message
    cd "${workingdir}"
}

trap cleanup EXIT
set -o nounset -o errexit

cd helloios

# Check if at least one command-line argument is provided
if [ "$#" -gt 0 ]; then
    # Check if the "-clean" parameter is provided
    if [ "$1" == "-clean" ]; then
        echo "\033[0;33mCleaning build directories...\033[0m" # Yellow color for cleaning message
        if [ -d "target" ]; then
            rm -rf "target"
        fi
    else
        echo "\033[0;31mUnrecognized argument: $1\033[0m" # Red color for error message
        echo "\033[0;33mUsage: $0 [-clean]\033[0m" # Yellow color for usage message
        echo "\033[0;33m       -clean: Optional. Cleans the build directories before building.\033[0m"
        exit 1
    fi
fi

# recreate headers
echo "\033[0;34mRecreating headers...\033[0m" # Blue color for status message
cbindgen src/lib.rs -l c > include/helloios.h

# Function to build for a specific target with optional nightly parameter
build_target() {
    target="$1"
    use_nightly="${2:-}"

    echo "\033[0;34mBuilding for target $target...\033[0m"

    if [ "$use_nightly" = "nightly" ]; then
        build_command="cargo +nightly build --release -Z build-std --target $target"
    else
        build_command="cargo build --release --target $target"
    fi

    if ! $build_command; then
        echo "\033[0;31mBuild failed for target $target\033[0m"
        exit 1
    fi
}

# Building possible architectures
build_target aarch64-apple-ios
build_target aarch64-apple-ios-sim
build_target aarch64-apple-darwin
build_target x86_64-apple-ios
build_target x86_64-apple-darwin

# Nightly builds
build_target aarch64-apple-ios-macabi nightly
build_target x86_64-apple-ios-macabi nightly

# display all build targets
echo "\033[0;34mLocating build targets...\033[0m"
find target -type f -name 'libhelloios.a'

# End
echo "\033[0;32mScript execution completed successfully.\033[0m"
exit 0
