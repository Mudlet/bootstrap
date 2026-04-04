#!/bin/bash

echo "=== Cloning Qt Source Repository ==="
cd ${RUNNER_WORKSPACE}
git clone --branch v6.9.1 --depth 1 --no-recurse-submodules https://github.com/qt/qt5.git qt6-source
cd qt6-source
git submodule update --init qtbase qttools

echo "=== Configuring Qt for Static Linking ==="
#perl init-repository --module-subset=qtbase
cd ${RUNNER_WORKSPACE}
mkdir qt-static-build
cd qt-static-build
export CMAKE_SUPPRESS_DEVELOPER_WARNINGS=ON

# Configure Qt with proper static dependencies
../qt6-source/configure -prefix ${RUNNER_WORKSPACE}/qt-static-install \
  -static -static-runtime -release -opensource -no-shared -confirm-license \
  -init-submodules -submodules qtbase,qttools \
  -nomake tests -nomake examples \
  -skip qt3d -skip qtmultimedia -skip qtdeclarative -skip qtshadertools -skip qtquick -skip designer \
  -no-opengl -no-dbus \
  -qt-pcre \
  -openssl-linked \
  -- \
  -DFEATURE_system_pcre2=OFF  

echo "=== Compiling Qt ==="
cmake --build . --parallel

echo "=== Installing Qt ==="
cmake --install .

echo "=== Verifying Installation ==="

# Check specifically for StateMachine
if [[ -d "${RUNNER_WORKSPACE}/qt-static-install/lib/cmake/Qt6ScXML" ]]; then
    echo "Qt ScXML successfully installed!"
else
    echo "Qt ScXML not found!"
    echo "Let's try to download and build ScXML separately..."
    
    # Alternative: Try to download ScXML from Qt's additional libraries
    cd ${RUNNER_WORKSPACE}
    mkdir qt-scxml-build
    cd qt-scxml-build
    
    # Try downloading from Qt's additional libraries (this may or may not work)
    wget -q https://download.qt.io/official_releases/qt/6.9/6.9.1/submodules/qtscxml-everywhere-src-6.9.1.tar.xz || \
    echo "Could not download ScXML from additional libraries"
    
    if [[ -f qtscxml-everywhere-src-6.9.1.tar.xz ]]; then
        echo "Found ScXML source, building..."
        tar xf qtscxml-everywhere-src-6.9.1.tar.xz
        cd qtscxml-everywhere-src-6.9.1
        mkdir build && cd build
        cmake .. \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_PREFIX_PATH=${RUNNER_WORKSPACE}/qt-static-install \
            -DCMAKE_INSTALL_PREFIX=${RUNNER_WORKSPACE}/qt-static-install \
            -DBUILD_SHARED_LIBS=OFF \
            -DQT_BUILD_SHARED_LIBS=OFF \
            -G Ninja
        cmake --build . --parallel
        cmake --install .
    else
        echo "ScXML source not found in official releases"
        exit 1
    fi
fi

echo "=== Final verification ==="
if [[ -d "${RUNNER_WORKSPACE}/qt-static-install/lib/cmake/Qt6ScXML" ]]; then
    echo "Qt ScXML successfully installed!"
else
    echo "Qt ScXML still not found after all attempts"
    exit 1
fi