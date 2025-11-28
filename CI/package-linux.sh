#!/bin/bash

# set -e
set -x

SOURCE_DIR="${GITHUB_WORKSPACE}"

# unset LD_LIBRARY_PATH as it upsets linuxdeployqt
export LD_LIBRARY_PATH=

echo "== Creating an AppImage =="

# setup linuxdeployqt binary if not found
if [ "$(getconf LONG_BIT)" = "64" ]; then
  if [[ ! -e linuxdeployqt.AppImage ]]; then
      # download prepackaged linuxdeployqt. Doesn't seem to have a "latest" url yet
      echo "linuxdeployqt not found - downloading one."
      wget --quiet -O linuxdeployqt.AppImage https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage
      chmod +x linuxdeployqt.AppImage
  fi
else
  echo "32bit Linux is currently not supported by the AppImage."
  exit 2
fi

mkdir "${GITHUB_WORKSPACE}/upload/"

# Check if this is a tagged release
IS_RELEASE=false
if [[ "${GITHUB_REF}" == refs/tags/* ]]; then
  IS_RELEASE=true
  echo "=== Building for RELEASE ==="
  mkdir -p "${GITHUB_WORKSPACE}/extracted-games"
else
  echo "=== Building for regular build ==="
fi

echo "Working in directory:"
pwd

while IFS= read -r line || [[ -n "$line" ]]; do
  gameName=$(echo "$line" | tr -cd '[:alnum:]_-')

  # create app directory for building the AppImage
  mkdir app
  mkdir app/lib

  cp build-${gameName}/MudletInstaller app/

  cp "$SOURCE_DIR"/mudlet{.png,.svg} app/
  cp "$SOURCE_DIR"/mudletinstaller.desktop app/

  ./linuxdeployqt.AppImage --appimage-extract

  # Bundle libssl.so so Mudlet works on platforms that only distribute
  # OpenSSL 1.1
  cp -L /usr/lib/x86_64-linux-gnu/libssl.so* \
        app/lib/ || true
  cp -L /lib/x86_64-linux-gnu/libssl.so* \
        app/lib/ || true
  if [ -z "$(ls app/lib/libssl.so*)" ]; then
    echo "No OpenSSL libraries to copy found. Aborting..."
  fi

  ./squashfs-root/AppRun ./app/MudletInstaller -appimage \
    -executable=app/lib/libssl.so.1.1 \
    -executable=app/lib/libssl.so.1.0.0

  # clean up extracted appimage
  rm -rf squashfs-root/

  BUILD_COMMIT=$(git rev-parse --short HEAD)

  mv MudletInstaller-${BUILD_COMMIT}-x86_64.AppImage MudletInstaller.AppImage
  chmod +x "MudletInstaller.AppImage"
  tar -cvf "MudletInstaller-linux-x64.AppImage.tar" "MudletInstaller.AppImage"

  mv "MudletInstaller-linux-x64.AppImage.tar" "${GITHUB_WORKSPACE}/upload/MudletInstaller-linux-x64-${gameName}.AppImage.tar"

  # If this is a release, also copy to extracted-games with standardized naming
  if [ "$IS_RELEASE" = true ]; then
    echo "Creating release version for $gameName"
    mkdir -p "${GITHUB_WORKSPACE}/extracted-games/$gameName"
    cp "${GITHUB_WORKSPACE}/upload/MudletInstaller-linux-x64-${gameName}.AppImage.tar" \
       "${GITHUB_WORKSPACE}/extracted-games/$gameName/MudletInstaller-$gameName-Linux.AppImage.tar"
  fi

  rm -rf app/
done < "${GITHUB_WORKSPACE}/GameList.txt"

echo "=== ... later, via Github ==="
# Move the finished file into a folder of its own, because we ask Github to upload contents of a folder

ls ${GITHUB_WORKSPACE}/upload

if [ "$IS_RELEASE" = true ]; then
  echo "=== Release files created ==="
  find "${GITHUB_WORKSPACE}/extracted-games" -type f | sort
fi

{
  echo "FOLDER_TO_UPLOAD=${GITHUB_WORKSPACE}/upload"
  echo "UPLOAD_FILENAME=MudletInstaller-linux-x64"
} >> "$GITHUB_ENV"
DEPLOY_URL="Github artifact, see https://github.com/$GITHUB_REPOSITORY/runs/$GITHUB_RUN_ID"

export DEPLOY_URL

