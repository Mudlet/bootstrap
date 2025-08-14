cmake_minimum_required(VERSION 3.25)
project(MudletBootstrap VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(WIN32)
    add_definitions(-DPCRE2_STATIC)
    set(QT_STATIC ON)
    set(BUILD_SHARED_LIBS OFF)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
    
    # Enable static runtime linking (GCC/MinGW)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static -static-libgcc -static-libstdc++")
    
    # Add libraries directly to linker flags - this forces them to be linked
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static -Wl,--gc-sections")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -L/mingw64/lib")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lpcre2-16 -lbz2 -lz -lpng -ljpeg -lfreetype -lharfbuzz")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lzstd -lb2 -lbrotlidec -lbrotlicommon")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -lws2_32 -lwinmm -limm32 -lwtsapi32 -ldwmapi -luxtheme")
endif()

find_package(QT NAMES Qt6 REQUIRED COMPONENTS Core Widgets Network)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Widgets Network)
find_package(Qt6LinguistTools)

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