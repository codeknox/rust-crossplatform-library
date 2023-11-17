#!/bin/sh

workingdir="$(pwd)"

function cleanup() {
    cd ${workingdir}
}

trap cleanup EXIT
set -o nounset -o errexit

cd helloios

# Check if at least one command-line argument is provided
if [ "$#" -gt 0 ]; then
    # Check if the "-clean" parameter is provided
    if [ "$1" == "-clean" ]; then
        # Delete the "target" folder immediately
        if [ -d "target" ]; then
            rm -rf "target"
        fi
    fi
fi

# recreate headers
cbindgen src/lib.rs -l c > include/helloios.h


# Building possible architectures

# arm
cargo build --release --target aarch64-apple-ios
cargo build --release --target aarch64-apple-ios-sim
cargo build --release --target aarch64-apple-darwin
cargo +nightly build --release -Z build-std --target aarch64-apple-ios-macabi

# x86
cargo build --release --target x86_64-apple-ios
cargo build --release --target x86_64-apple-darwin
cargo +nightly build --release -Z build-std --target x86_64-apple-ios-macabi

# find all build targets
find target -type f -name 'libhelloios.a'

# build XCFrameworks
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

# list architectures in each file
lipo -info target/libhelloios_macos.a
lipo -info target/libhelloios_iossimulator.a
lipo -info target/libhelloios_maccatalyst.a

echo "creating XCFramework..."

# create XCFramework bundle
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

mkdir -p ../ios/include
cp include/helloios.h ../ios/include

mkdir -p ../ios/libs
rm -rf ../ios/libs/LibHello.xcframework
cp -r target/LibHello.xcframework ../ios/libs

exit 0