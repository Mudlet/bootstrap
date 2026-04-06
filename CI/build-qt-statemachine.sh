#!/bin/bash

# Script to build Qt StateMachine module from source
# This works for both Linux and macOS

set -e

echo "=== Building Qt ScXML Module from Source ==="

# Set variables
QT_STATEMACHINE_VERSION="${QT_VERSION}"
WORKSPACE_DIR="${RUNNER_WORKSPACE:-$HOME/bootstrap}"
QT_DIR="${WORKSPACE_DIR}/Qt/${QT_STATEMACHINE_VERSION}/$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m)"

# For GitHub Actions, use the detected compiler
if [[ "$RUNNER_OS" == "Linux" ]]; then
    QT_DIR="${WORKSPACE_DIR}/Qt/${QT_STATEMACHINE_VERSION}/gcc_64"
elif [[ "$RUNNER_OS" == "macOS" ]]; then
    QT_DIR="${WORKSPACE_DIR}/Qt/${QT_STATEMACHINE_VERSION}/macos"
fi

echo "Qt directory: $QT_DIR"
echo "Workspace directory: $WORKSPACE_DIR"

# Create build directory
BUILD_DIR="${WORKSPACE_DIR}/qt-scxml-build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Download Qt SCXML source from official Qt releases
echo "=== Downloading Qt SCXML source from official releases ==="
QT_MINOR="${QT_VERSION%.*}"
SCXML_URL="https://download.qt.io/official_releases/qt/${QT_MINOR}/${QT_VERSION}/submodules/qtscxml-everywhere-src-${QT_VERSION}.tar.xz"

if [[ ! -f "qtscxml-everywhere-src-${QT_VERSION}.tar.xz" ]]; then
    echo "Downloading $SCXML_URL"
    wget -q "$SCXML_URL" || {
        echo "Failed to download Qt SCXML source"
        exit 1
    }
fi

# Extract the source
echo "=== Extracting Qt SCXML source ==="
if [[ ! -d "qtscxml-everywhere-src-${QT_VERSION}" ]]; then
    tar xf "qtscxml-everywhere-src-${QT_VERSION}.tar.xz"
fi

cd "qtscxml-everywhere-src-${QT_VERSION}"

# Configure
echo "=== Configuring Qt ScXML build ==="
mkdir -p build
cd build

cmake .. \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$QT_DIR" \
    -DCMAKE_PREFIX_PATH="$QT_DIR"

# Build and install
echo "=== Building Qt ScXML ==="
cmake --build . --parallel

echo "=== Installing Qt ScXML ==="
cmake --install .

# Verify installation
echo "=== Verifying Qt ScXML installation ==="
if [[ -d "$QT_DIR/lib/cmake/Qt6Scxml" ]]; then
    echo "Qt ScXML successfully installed!"

    # Also check if StateMachine functionality is available
    if [[ -d "$QT_DIR/lib/cmake/Qt6StateMachine" ]]; then
        echo "Qt StateMachine also found!"
    elif find "$QT_DIR" -name "*StateMachine*" -type f | grep -q .; then
        echo "StateMachine files found:"
        find "$QT_DIR" -name "*StateMachine*" -type f
    else
        echo "Qt StateMachine not found, but ScXML provides state machine functionality"
    fi
else
    echo "Qt ScXML installation failed!"
    echo "Checking for any ScXML files:"
    find "$QT_DIR" -name "*Scxml*" -type f || echo "No ScXML files found"
    exit 1
fi

echo "=== Qt ScXML build complete ==="