#!/usr/bin/env bash

# Fail immediately in case of errors and/or unset variables
set -eu -o pipefail

# Echo commands so that the progress can be seen in CI server logs.
set -x

# Detect installed Java
export JAVA_HOME="$(java -XshowSettings:properties -version \
    2>&1 > /dev/null |\
    grep 'java.home' |\
    awk '{print $3}')"

export LD_LIBRARY_PATH="$(find -L ${JAVA_HOME} -type f -name libjvm.* | xargs -n1 dirname)"

# Install clippy
if [[ ${TRAVIS_RUST_VERSION} == "nightly" ]];
then
    # Install nightly clippy
    rustup component add clippy --toolchain=nightly || cargo install --git https://github.com/rust-lang/rust-clippy/ --force clippy
else
    # Install stable clippy
    rustup component add clippy
fi
cargo clippy -V

# Install rustfmt
rustup component add rustfmt
rustfmt -V

echo 'Performing checks over the rust code'
# Check the formatting.
cargo fmt --all -- --check

# Run clippy static analysis.
cargo clippy --all --tests --all-features -- -D warnings

# Run tests with default features (stable-only)
if [[ ${TRAVIS_RUST_VERSION} == "stable" ]]; then
  cargo test
fi

# Run all tests with invocation feature (enables JavaVM ITs)
cargo test --features=backtrace,invocation
