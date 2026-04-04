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
#          1.5.0    No change
#          1.4.0    No change
#          1.3.0    Don't explicitly install the no longer supported QT 5
#                   Gamepad stuff (since PR #6787 was merged into
#                   development branch) - it may still be installed as part
#                   of a Qt5 installation but we don't use it any more.
#          1.2.0    Tweak luarocks --tree better and report on failure to
#                   complete
#          1.1.0    Updated to not do things that have already been done
#                   and to offer a choice between a base or a full install
#          1.0.0    Original version

# Script to run once in a ${GITHUB_WORKFLOW} directory in a MSYS2 shell to
# install as much as possible to be able to develop 64/32 Bit Windows
# version of Mudlet

# To be used prior to building Mudlet, after that run:
# * build-mudlet-for-window.sh to compile the currently checked out code
# * package-mudlet-for-windows.sh to put everything together in an archive that
#   will be deployed from a github workflow

# Exit codes:
# 0 - Everything is fine. 8-)
# 1 - Failure to change to a directory
# 2 - Unsupported MSYS2/MINGGW shell type
# 5 - Invalid command line argument
# 6 - One or more Luarocks could not be installed
# 7 - One of more packages failed to install


if [ "${MSYSTEM}" != "CLANG64" ]; then
  echo "Please run this script from a CLANG64 type bash terminal."
  echo "Current MSYSTEM is: ${MSYSTEM}"
  exit 2
fi

export MINGW_BASE_DIR="${MSYSTEM_PREFIX}"
export PATH="${MINGW_BASE_DIR}/usr/local/bin:${MINGW_BASE_DIR}/bin:/usr/bin:${PATH}"
echo "MSYSTEM is: ${MSYSTEM}"
echo "PATH is now: ${PATH}"
echo ""

# Options to consider:
# --Sy = Sync, refresh as well as installing the specified packages
# --noconfirm = do not ask for user intervention
# --noprogressbar = do not show progress bars as they are not useful in scripts
echo "  Updating and installing ${MSYSTEM} packages..."
echo ""
echo "    This could take a long time if it is needed to fetch everything, so feel free"
echo "    to go and have a cup of tea (other beverages are available) in the meantime...!"
echo ""


#echo "=== Installing Qt6 Packages ==="
#pacman_attempts=1
#while true; do
#    if /usr/bin/pacman -Su --needed --noconfirm \
#        "mingw-w64-${BUILDCOMPONENT}-qt6-base" \
#        "mingw-w64-${BUILDCOMPONENT}-qt6-tools"; then
#        break
#    fi

#    if [ $pacman_attempts -eq 10 ]; then
#        exit 7
#    fi
#    pacman_attempts=$((pacman_attempts +1))

#    echo "=== Some packages failed to install, waiting and trying again ==="
#    sleep 10
#done


pacman_attempts=1
while true; do
  if /usr/bin/pacman -Su --needed --noconfirm \
    git \
    man \
    rsync \
    python \
    perl \
    bison \
    flex \
    "${MINGW_PACKAGE_PREFIX}-ccache" \
    "${MINGW_PACKAGE_PREFIX}-ntldd" \
    "${MINGW_PACKAGE_PREFIX}-toolchain" \
    "${MINGW_PACKAGE_PREFIX}-zlib" \
    "${MINGW_PACKAGE_PREFIX}-icu" \
    "${MINGW_PACKAGE_PREFIX}-openssl" \
    "${MINGW_PACKAGE_PREFIX}-cmake" \
    "${MINGW_PACKAGE_PREFIX}-ninja" \
    "${MINGW_PACKAGE_PREFIX}-pcre2" \
    "${MINGW_PACKAGE_PREFIX}-bzip2" \
    "${MINGW_PACKAGE_PREFIX}-qt6-tools" \
    "${MINGW_PACKAGE_PREFIX}-qt6-translations" \
    "${MINGW_PACKAGE_PREFIX}-freetype" \
    "${MINGW_PACKAGE_PREFIX}-harfbuzz" \
    "${MINGW_PACKAGE_PREFIX}-libjpeg-turbo" \
    "${MINGW_PACKAGE_PREFIX}-libpng" \
    "${MINGW_PACKAGE_PREFIX}-zstd" \
    "${MINGW_PACKAGE_PREFIX}-libb2" \
    "${MINGW_PACKAGE_PREFIX}-brotli" \
    "${MINGW_PACKAGE_PREFIX}-graphite2" \
    "${MINGW_PACKAGE_PREFIX}-gettext"; then
      break
  fi

  if [ $pacman_attempts -eq 10 ]; then
    exit 7
  fi
  pacman_attempts=$((pacman_attempts +1))

  echo "=== Some packages failed to install, waiting and trying again ==="
  sleep 10
done

#export CC="ccache gcc"
#export CXX="ccache g++"
ccache --max-size=10G

#echo "=== Listing Environment Variables ==="
#printenv

echo "Debugging libbz2 symbols"
echo "BZ2 library:"
find ${MSYSTEM_PREFIX}/lib -name "*bz2*" -type f
echo "PCRE2 library:"
find ${MSYSTEM_PREFIX}/lib -name "*pcre2*" -type f
echo "Freetype library:"
find ${MSYSTEM_PREFIX}/lib -name "*freetype*" -type f

exit 0