#!/bin/bash
###########################################################################
#   Copyright (C) 2024-2024  by John McKisson - john.mckisson@gmail.com   #
#   Copyright (C) 2023-2024  by Stephen Lyons - slysven@virginmedia.com   #
#                                                                         #
#   This program is free software; you can redistribute it and/or modify  #
#   it under the terms of the GNU General Public License as published by  #
#   the Free Software Foundation; either version 2 of the License, or     #
#   (at your option) any later version.                                   #
#                                                                         #
#   This program is distributed in the hope that it will be useful,       #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#   GNU General Public License for more details.                          #
#                                                                         #
#   You should have received a copy of the GNU General Public License     #
#   along with this program; if not, write to the                         #
#   Free Software Foundation, Inc.,                                       #
#   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
###########################################################################

# Version: 2.0.0    Rework to build on an MSYS2 MINGW64 Github workflow

# Exit codes:
# 0 - Everything is fine. 8-)
# 1 - Failure to change to a directory
# 2 - Unsupported fork
# 3 - Not used
# 4 - nuget error
# 5 - squirrel error

if [ "${MSYSTEM}" != "CLANG64" ]; then
  echo "Please run this script from a CLANG64 type bash terminal."
  echo "Current MSYSTEM is: ${MSYSTEM}"
  exit 2
fi

cd "$GITHUB_WORKSPACE" || exit 1

GITHUB_WORKSPACE_UNIX_PATH=$(echo "${GITHUB_WORKSPACE}" | sed 's|\\|/|g' | sed 's|D:|/d|g')

echo "=== Setting up upload directory ==="
uploadDir="${GITHUB_WORKSPACE}\\upload"
uploadDirUnix=$(echo "${uploadDir}" | sed 's|\\|/|g' | sed 's|D:|/d|g')

# Check if the upload directory exists, if not, create it
if [[ ! -d "$uploadDirUnix" ]]; then
  mkdir -p "$uploadDirUnix"
fi

# Check if this is a tagged release
IS_RELEASE=false
if [[ "${GITHUB_REF}" == refs/tags/* ]]; then
  IS_RELEASE=true
  echo "=== Building for RELEASE ==="
  mkdir -p "${GITHUB_WORKSPACE_UNIX_PATH}/extracted-games"
else
  echo "=== Building for regular build ==="
fi

# Set up Java for code signing if Azure token is available
if [ -n "${AZURE_ACCESS_TOKEN}" ]; then
  echo "=== Setting up Java 21 for signing ==="
  # Java is installed by default, we just need to select which version to use:
  JAVA_HOME="$(cygpath -au "${JAVA_HOME_21_X64}")"
  export JAVA_HOME
  export PATH="${JAVA_HOME}/bin:${PATH}"
  JAVA_JAR_WINPATHFILE="$(cygpath -aw "${GITHUB_WORKSPACE}/CI/jsign-7.0-SNAPSHOT.jar")"
  echo "Java setup complete for code signing"
else
  echo "=== Code signing skipped - no Azure token provided ==="
fi

while IFS= read -r line || [[ -n "$line" ]]; do

  gameName=$(echo "$line" | tr -cd '[:alnum:]_-')

  PACKAGE_DIR="${GITHUB_WORKSPACE_UNIX_PATH}/package-${gameName}"

  cd "$PACKAGE_DIR" || exit 1

  # Remove specific file types from the directory
  rm ./*.cpp ./*.o

  mv "$PACKAGE_DIR/MudletInstaller.exe" "MudletInstaller-${gameName}.exe"

  # Sign the executable if Azure token is available
  if [ -n "${AZURE_ACCESS_TOKEN}" ]; then
    echo "=== Signing MudletInstaller-${gameName}.exe ==="
    EXECUTABLE_WINPATH="$(cygpath -aw "${PACKAGE_DIR}/MudletInstaller-${gameName}.exe")"
    java.exe -jar "${JAVA_JAR_WINPATHFILE}" \
      --storetype TRUSTEDSIGNING \
      --keystore eus.codesigning.azure.net \
      --storepass "${AZURE_ACCESS_TOKEN}" \
      --alias Mudlet/Mudlet \
      "${EXECUTABLE_WINPATH}"
    echo "Signing completed for MudletInstaller-${gameName}.exe"
  fi

  # Move packaged files to the upload directory
  echo "=== Copying files to upload directory ==="
  #rsync -avR "${PACKAGE_DIR}"/./* "$uploadDirUnix"
  cp -r "${PACKAGE_DIR}/"* "$uploadDirUnix"

  # If this is a release, also copy to extracted-games with standardized naming
  if [ "$IS_RELEASE" = true ]; then
    echo "Creating release version for $gameName"
    mkdir -p "${GITHUB_WORKSPACE_UNIX_PATH}/extracted-games/$gameName"
    cp "${PACKAGE_DIR}/MudletInstaller-${gameName}.exe" \
       "${GITHUB_WORKSPACE_UNIX_PATH}/extracted-games/$gameName/MudletInstaller-$gameName-Windows.exe"
  fi

  cd "$GITHUB_WORKSPACE" || exit 1

done < "${GITHUB_WORKSPACE}/GameList.txt"

if [ "$IS_RELEASE" = true ]; then
  echo "=== Release files created ==="
  find "${GITHUB_WORKSPACE_UNIX_PATH}/extracted-games" -type f | sort
fi

# Append these variables to the GITHUB_ENV to make them available in subsequent steps
{
  echo "FOLDER_TO_UPLOAD=${uploadDir}\\"
  echo "UPLOAD_FILENAME=MudletInstaller-${MSYSTEM}"
} >> "$GITHUB_ENV"
