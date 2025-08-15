cmake_minimum_required(VERSION 3.25)
project(MudletBootstrap VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(WIN32)
    set(QT_STATIC ON)
    set(BUILD_SHARED_LIBS OFF)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
    
    # Enable static runtime linking (GCC/MinGW)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static -static-libgcc -static-libstdc++")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static -Wl,--gc-sections")

endif()

# Explicitly prevent CMake from finding system Qt6 when we want static build
if(WIN32 AND DEFINED CMAKE_PREFIX_PATH)
    set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
    set(QT_NO_CMAKE_PACKAGE_CACHE ON)
endif()


find_package(QT NAMES Qt6 REQUIRED COMPONENTS Core Widgets Network)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Widgets Network)
find_package(Qt6LinguistTools QUIET)

if(NOT Qt6LinguistTools_FOUND)
    message(STATUS "Qt6LinguistTools not found in static build, trying system installation...")
    # If not found, try to find it in the system installation
    find_path(Qt6LinguistTools_DIR
        NAMES Qt6LinguistToolsConfig.cmake
        PATHS
            /mingw64/lib/cmake/Qt6LinguistTools
            /mingw64/share/cmake/Qt6LinguistTools
        NO_DEFAULT_PATH
    )
    if(Qt6LinguistTools_DIR)
        find_package(Qt6LinguistTools PATHS ${Qt6LinguistTools_DIR} NO_DEFAULT_PATH)
    endif()
endif()

if(Qt6LinguistTools_FOUND)
    message(STATUS "Found Qt6LinguistTools at: ${Qt6LinguistTools_DIR}")
else()
    message(WARNING "Qt6LinguistTools not found - translations will be disabled")
endif()


set(TS_FILES MudletBootstrap_en_US.ts)
set(PROJECT_SOURCES
        main.cpp
        MudletBootstrap.h
        MudletBootstrap.cpp
        ${TS_FILES}
)

qt_add_executable(MudletBootstrap
    MANUAL_FINALIZATION
    ${PROJECT_SOURCES}
)

# Add resources
qt_add_resources(RESOURCES resources.qrc)
target_sources(MudletBootstrap PRIVATE ${RESOURCES})

# Link Qt libraries
target_link_libraries(MudletBootstrap PRIVATE
    Qt${QT_VERSION_MAJOR}::Widgets
    Qt${QT_VERSION_MAJOR}::Network
)


if(WIN32)
    # Detect the correct MSYS2 path (different between local and GitHub Actions)
    if(EXISTS "C:/a/_temp/msys64/mingw64/lib")
        # GitHub Actions path
        set(MSYS2_LIB_PATH "C:/a/_temp/msys64/mingw64/lib")
    elseif(EXISTS "C:/msys64/mingw64/lib")
        # Local MSYS2 path
        set(MSYS2_LIB_PATH "C:/msys64/mingw64/lib")
    else()
        # Fallback: try to detect from compiler path
        get_filename_component(COMPILER_DIR ${CMAKE_CXX_COMPILER} DIRECTORY)
        get_filename_component(MSYS2_ROOT ${COMPILER_DIR} DIRECTORY)
        get_filename_component(MSYS2_ROOT ${MSYS2_ROOT} DIRECTORY)
        set(MSYS2_LIB_PATH "${MSYS2_ROOT}/lib")
        message(STATUS "Detected MSYS2 lib path from compiler: ${MSYS2_LIB_PATH}")
    endif()
    
    message(STATUS "Using MSYS2 lib path: ${MSYS2_LIB_PATH}")
    
    # Verify the libraries exist
    if(NOT EXISTS "${MSYS2_LIB_PATH}/libbz2.a")
        message(FATAL_ERROR "libbz2.a not found at ${MSYS2_LIB_PATH}/libbz2.a")
    endif()
    if(NOT EXISTS "${MSYS2_LIB_PATH}/libbrotlicommon.a")
        message(FATAL_ERROR "libbrotlicommon.a not found at ${MSYS2_LIB_PATH}/libbrotlicommon.a")
    endif()

    # Don't link libraries early - let Qt's dependencies handle them
    # Just ensure they're available at the end with --whole-archive
    target_link_options(MudletBootstrap PRIVATE
        "LINKER:--whole-archive"
        "LINKER:C:/a/_temp/msys64/mingw64/lib/libbz2.a"
        "LINKER:C:/a/_temp/msys64/mingw64/lib/libbrotlicommon.a"
        "LINKER:--no-whole-archive"
    )

    # Only link Windows system libraries
    target_link_libraries(MudletBootstrap PRIVATE
        ws2_32 winmm imm32 wtsapi32 dwmapi uxtheme
        rpcrt4 crypt32 secur32 ole32 oleaut32 uuid
        advapi32 shell32 user32 kernel32 gdi32 comdlg32 winspool
    )
endif()


message(STATUS
    "Project Version: ${PROJECT_VERSION}\n"
    "Project Version Major: ${PROJECT_VERSION_MAJOR}\n"
    "Project Version Minor: ${PROJECT_VERSION_MINOR}"
)

set_target_properties(MudletBootstrap PROPERTIES
    ${BUNDLE_ID_OPTION}
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE_LONG_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_ICON_FILE mudlet.icns
    MACOSX_BUNDLE_BUNDLE_NAME MudletBootstrap
    MACOSX_BUNDLE_GUI_IDENTIFIER org.mudlet.bootstrap
    WIN32_EXECUTABLE TRUE
)

if(APPLE)
    file(GLOB ICON_FILE "mudlet.icns")
    message(STATUS "Using icon file: ${ICON_FILE}")
    target_sources(MudletBootstrap PRIVATE ${ICON_FILE})
    set_source_files_properties(${ICON_FILE} PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
endif()

include(GNUInstallDirs)
install(TARGETS MudletBootstrap
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if(QT_VERSION_MAJOR EQUAL 6)
    qt_finalize_executable(MudletBootstrap)
endif()