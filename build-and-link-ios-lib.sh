#!/bin/sh

# If you are going to edit this script, please follow the color codes used in your echo statements:
# 
# SUCCESS/Green: Success or completion messages.
# WARNING/Yellow: Warning or process-start messages.
# INFO/Blue: Information or ongoing process messages.
# ERROR/Red: Error messages.

# Define color codes
readonly SUCCESS="\033[0;32m"
readonly WARNING="\033[0;33m"
readonly INFO="\033[0;34m"
readonly ERROR="\033[0;31m"
readonly RESET="\033[0m" # Resets color to default

# Logging function
log() {
    local level=$1
    local message=$2
    local color=""
    local prefix=""

    case $level in
        SUCCESS) color=$SUCCESS; prefix="SUCCESS:" ;;
        WARNING) color=$WARNING; prefix="WARNING:" ;;
        INFO) color=$INFO; prefix="INFO:" ;;
        ERROR) color=$ERROR; prefix="ERROR:" ;;
        *) color=$RESET; prefix="LOG:" ;;
    esac

    echo "${color}${prefix} ${message}${RESET}"
}

workingdir="$(pwd)"

cleanup() {
    log SUCCESS "cleaning up..."
    cd "${workingdir}"
}

trap cleanup EXIT
set -o nounset -o errexit

cd helloios

# Check if at least one command-line argument is provided
if [ "$#" -gt 0 ]; then
    # Check if the "-clean" parameter is provided
    if [ "$1" == "-clean" ]; then
        log WARNING "Cleaning build directories..."
        if [ -d "target" ]; then
            rm -rf "target"
        fi
    else
        log ERROR "Unrecognized argument: $1"
        log WARNING "Usage: $0 [-clean]"
        log WARNING "       -clean: Optional. Cleans the build directories before building."
        exit 1
    fi
fi

# recreate headers
log INFO "Recreating headers..."
cbindgen src/lib.rs -l c > include/helloios.h

# Function to build for a specific target with optional nightly parameter
build_target() {
    target="$1"
    use_nightly="${2:-}"

    log INFO "Building for target $target..."

    if [ "$use_nightly" = "nightly" ]; then
        build_command="cargo +nightly build --release -Z build-std --target $target"
    else
        build_command="cargo build --release --target $target"
    fi

    if ! $build_command; then
        log ERROR "Build failed for target $target"
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
log INFO "Locating build targets..."
find target -type f -name 'libhelloios.a'

# copying headers
log INFO "Copying headers..."

mkdir -p ../ios/include
cp include/helloios.h ../ios/include

# creating XCFramework bundle
log INFO "Creating XCFramework bundle..."

# building bundled architecture files
log INFO "Building bundled architecture files"

lipo -create \
  target/x86_64-apple-darwin/release/libhelloios.a \
  target/aarch64-apple-darwin/release/libhelloios.a \
  -output target/libhelloios_macos.a

lipo -create \
  target/x86_64-apple-ios/release/libhelloios.a \
  target/aarch64-apple-ios-sim/release/libhelloios.a \
  -output target/libhelloios_iossimulator.a

lipo -create \
  target/x86_64-apple-ios-macabi/release/libhelloios.a \
  target/aarch64-apple-ios-macabi/release/libhelloios.a \
  -output target/libhelloios_maccatalyst.a

# listing architectures in each file
log INFO "Listing architectures in each file..."
lipo -info target/libhelloios_macos.a
lipo -info target/libhelloios_iossimulator.a
lipo -info target/libhelloios_maccatalyst.a

log INFO "Building final XCFramework file..."

rm -rf target/LibHello.xcframework
xcodebuild -create-xcframework \
  -library target/libhelloios_macos.a \
  -headers include/ \
  -library target/libhelloios_iossimulator.a \
  -headers include/ \
  -library target/libhelloios_maccatalyst.a \
  -headers include/ \
  -library target/aarch64-apple-ios/release/libhelloios.a \
  -headers include/ \
  -output target/LibHello.xcframework

# copying XCFramework
log INFO "Copying XCFramework..."
mkdir -p ../ios/libs
rm -rf ../ios/libs/LibHello.xcframework
cp -r target/LibHello.xcframework ../ios/libs

# End
log SUCCESS "Script execution completed successfully."
exit 0
