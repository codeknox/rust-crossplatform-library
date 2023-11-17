#!/bin/sh

cd helloios

cargo lipo --release --targets aarch64-apple-ios x86_64-apple-ios 
# aarch64-apple-ios 

cbindgen src/lib.rs -l c > include/helloios.h

mkdir -p ../ios/include
mkdir -p ../ios/libs

cp include/helloios.h ../ios/include
cp target/universal/release/libhelloios.a ../ios/libs