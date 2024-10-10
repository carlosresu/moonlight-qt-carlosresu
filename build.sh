#!/bin/bash
set -e  # Exit immediately if any command fails

### Common Setup for All Platforms ###

# Navigate to the moonlight-qt repository directory
cd ~/moonlight-qt-carlosresu

# Initialize and update the git submodules
git submodule update --init --recursive

# Fetch the latest changes from the upstream repository
git fetch upstream

# Merge the latest changes from upstream's master branch into your current branch and use a default commit message
git merge upstream/master -m "Merge upstream changes from master" || true

# Push the updated branch to your fork (origin)
git push origin master

# Success message for updating moonlight-qt
echo "Moonlight-qt repository successfully updated from upstream and pushed to your fork!"

# Navigate to the FFmpeg submodule in moonlight-qt
cd ~/moonlight-qt-carlosresu/FFmpeg-carlosresu

# Add remote for the official FFmpeg repo if it doesn't exist
if ! git remote | grep -q "upstream"; then
  git remote add upstream https://github.com/FFmpeg/FFmpeg.git
fi

git fetch upstream

# Checkout your branch
git checkout master

# Merge FFmpeg master branch into your branch
git merge upstream/master -m "Merge FFmpeg upstream/master into master" || true

# Push the updated branch to your fork
git push origin master --force

# Navigate back to the moonlight-qt directory and update the submodule reference
cd ~/moonlight-qt-carlosresu

# Stage the updated submodule reference
git add FFmpeg-carlosresu

# Commit the updated submodule reference
git commit -m "Update FFmpeg submodule to latest from upstream" || true

# Push the changes to your moonlight-qt repository
git push origin master

# Success message for updating FFmpeg
echo "FFmpeg submodule successfully updated from upstream, and pushed to your moonlight-qt fork!"

### Platform-specific Setup ###

# Detect platform and architecture
PLATFORM=$(uname)
ARCH=$(uname -m)

### macOS Setup ###
if [[ "$PLATFORM" == "Darwin" ]]; then
  echo "Setting up for macOS..."

  # Function to install Homebrew packages only if they aren't already installed
  install_if_missing() {
    for package in "$@"; do
      if ! brew list --formula | grep -q "^$package\$"; then
        echo "Installing $package..."
        brew install "$package"
      else
        echo "$package is already installed."
      fi
    done
  }

  # Install necessary tools for macOS
  if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew found. Updating Homebrew..."
    brew update
  fi

  echo "Installing macOS dependencies..."
  install_if_missing nasm yasm pkg-config automake autoconf cmake libtool texinfo git
  install_if_missing zlib x264 x265 fdk-aac libvpx libvorbis libass libbluray opencore-amr opus aom dav1d
  install_if_missing frei0r theora libvidstab libvmaf rav1e rubberband sdl2 snappy speex srt tesseract
  install_if_missing two-lame xvid xz fontconfig fribidi gnutls lame libsoxr openssl qt create-dmg

  # Skip unavailable dependencies or provide manual installation instructions
  echo "Note: You'll need to install 'librtmp' and 'libzmq' manually as they are not available in Homebrew."

  # Manual installation instructions
  echo "To install 'libzmq' manually, run the following commands:"
  echo "git clone https://github.com/zeromq/libzmq.git"
  echo "cd libzmq && ./autogen.sh && ./configure && make && sudo make install"

  echo "To install 'librtmp', run:"
  echo "git clone https://git.ffmpeg.org/rtmpdump.git"
  echo "cd rtmpdump/librtmp && make && sudo make install"

  # Set up FFmpeg build for macOS (ARM or x86)
  cd ~/moonlight-qt-carlosresu/FFmpeg-carlosresu
  ./build.sh  # Builds FFmpeg

  # Navigate back to the moonlight-qt directory
  cd ~/moonlight-qt-carlosresu

  # Create the target directory if it doesn't exist
  mkdir -p ./libs/mac/lib

  # Copy the necessary FFmpeg libraries to the moonlight-qt libs folder
  cp ./FFmpeg-carlosresu/libavutil/libavutil.59.dylib ./libs/mac/lib/libavutil.59.dylib
  cp ./FFmpeg-carlosresu/libavcodec/libavcodec.61.dylib ./libs/mac/lib/libavcodec.61.dylib

  # Run qmake to generate Makefiles
  qmake6 moonlight-qt.pro

  # Compile the project in debug mode
  make Debug

  # Copy the application to the Applications folder
  cp -R ./app/Moonlight.app /Applications/Moonlight.app

  # Clean the build
  make clean
  make distclean

  # Remove the copied FFmpeg libraries
  rm -rf ./libs/mac/lib/libavutil.59.dylib
  rm -rf ./libs/mac/lib/libavcodec.61.dylib

  # Create DMG for non-development use
  ./scripts/generate-dmg.sh

  echo "macOS build and file copy completed successfully!"

### Linux Setup ###
elif [[ "$PLATFORM" == "Linux" ]]; then
  echo "Setting up for Linux..."

  # Install necessary tools for Linux
  sudo apt update
  sudo apt install -y libegl1-mesa-dev libgl1-mesa-dev libopus-dev libsdl2-dev libsdl2-ttf-dev libssl-dev libavcodec-dev libavformat-dev libswscale-dev libva-dev libvdpau-dev libxkbcommon-dev wayland-protocols libdrm-dev qt6-base-dev qt6-declarative-dev libqt6svg6-dev qml6-module-qtquick-controls qml6-module-qtquick-templates qml6-module-qtquick-layouts qml6-module-qtqml-workerscript qml6-module-qtquick-window qml6-module-qtquick

  # Set up FFmpeg build for Linux
  cd ~/moonlight-qt-carlosresu/FFmpeg-carlosresu
  ./build.sh  # Builds FFmpeg

  # Navigate back to the moonlight-qt directory
  cd ~/moonlight-qt-carlosresu

  # Run qmake to generate Makefiles
  qmake6 moonlight-qt.pro

  # Compile the project in debug mode
  make Debug

  echo "Linux build completed successfully!"

### Windows Setup ###
elif [[ "$PLATFORM" == "MINGW"* || "$PLATFORM" == "CYGWIN"* || "$PLATFORM" == "MSYS"* ]]; then
  echo "Setting up for Windows..."

  # Install dependencies for Windows using a package manager like Chocolatey or manually
  choco install visualstudio2022community qt-sdk 7zip

  # Install Graphics Tools for debugging
  dism /online /add-capability /capabilityname:Tools.Graphics.DirectX~~~~0.0.1.0

  # Set up FFmpeg build for Windows
  cd ~/moonlight-qt-carlosresu/FFmpeg-carlosresu
  ./build.sh  # Builds FFmpeg

  # Navigate back to the moonlight-qt directory
  cd ~/moonlight-qt-carlosresu

  # Run qmake to generate Makefiles
  qmake6 moonlight-qt.pro

  # Compile the project in debug mode
  make Debug

  # Generate the Windows installer
  ./scripts/build-arch.bat
  ./scripts/generate-bundle.bat

  echo "Windows build completed successfully!"

else
  echo "Unsupported platform: $PLATFORM"
  exit 1
fi

brew cleanup
brew cleanup --prune=all
brew update-reset

# Final success message
echo "Moonlight-qt and FFmpeg have been successfully built and deployed for $PLATFORM!"