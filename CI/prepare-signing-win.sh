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

# Version: 1.0.0    Split out of deploy-win.sh when Windows signing moved from
#                   Azure Trusted Signing to SignPath. jsign signed each
#                   launcher in place; SignPath signs an uploaded artifact, so
#                   the launchers have to be named and gathered up first.

# Gives each launcher its release name and gathers them all into one directory
# for the workflow to hand to SignPath. One artifact for the whole GameList
# means one signing request rather than one per game.

# To be used AFTER package-win.sh has been run; deploy-win.sh then picks the
# signed launchers back up.

# Exit codes:
# 0 - Everything is fine. 8-)
# 1 - Failure to change to a directory
# 2 - Unsupported MSYS2/MINGW shell type
# 6 - No MudletInstaller.exe file found to work with

if [ "${MSYSTEM}" != "CLANG64" ]; then
  echo "Please run this script from a CLANG64 type bash terminal."
  echo "Current MSYSTEM is: ${MSYSTEM}"
  exit 2
fi

cd "$GITHUB_WORKSPACE" || exit 1

GITHUB_WORKSPACE_UNIX_PATH=$(echo "${GITHUB_WORKSPACE}" | sed 's|\\|/|g' | sed 's|D:|/d|g')

# Both rebuilt from scratch. signing-launchers/ is what gets uploaded, so a
# stale file in it would be signed and shipped. signed-launchers/ is where
# SignPath extracts the result over whatever is already there, so a stale file
# in it would be published as though it had just been signed.
signingDir="${GITHUB_WORKSPACE_UNIX_PATH}/signing-launchers"
signedDir="${GITHUB_WORKSPACE_UNIX_PATH}/signed-launchers"
rm -rf "${signingDir}" "${signedDir}"
mkdir -p "${signingDir}"

while IFS= read -r line || [[ -n "$line" ]]; do

  gameName=$(echo "$line" | tr -cd '[:alnum:]_-')

  PACKAGE_DIR="${GITHUB_WORKSPACE_UNIX_PATH}/package-${gameName}"

  cd "$PACKAGE_DIR" || exit 1

  # Remove specific file types from the directory
  rm -f ./*.cpp ./*.o

  if [ ! -f "${PACKAGE_DIR}/MudletInstaller.exe" ]; then
    echo "ERROR: no MudletInstaller executable found in ${PACKAGE_DIR} - did"
    echo "package-win.sh complete successfully?"
    exit 6
  fi

  mv "${PACKAGE_DIR}/MudletInstaller.exe" "MudletInstaller-${gameName}.exe"

  cp "${PACKAGE_DIR}/MudletInstaller-${gameName}.exe" "${signingDir}/"

  cd "$GITHUB_WORKSPACE" || exit 1

done < "${GITHUB_WORKSPACE}/GameList.txt"

echo "=== Launchers staged for signing ==="
ls -l "${signingDir}"
echo "Total staged: $(du -sh "${signingDir}" | cut -f1)"

# actions/upload-artifact runs in Node.js outside MSYS2 and misinterprets Unix
# paths like /d/a/... as D:\d\a\..., so hand it a native Windows path:
echo "SIGNING_DIR=$(cygpath -aw "${signingDir}")" >> "$GITHUB_ENV"

exit 0
