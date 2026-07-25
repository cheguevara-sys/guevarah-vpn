#!/usr/bin/env bash
# build.sh — Build the Guevarah VPN tunnel APK
#
# Run: bash build.sh
# Output: app/build/outputs/apk/debug/app-debug.apk

set -e

JDK_DIR="/tmp/jdk-17.0.11+9"
JDK_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.11_9.tar.gz"
SDK_DIR="$HOME/android-sdk"
SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

# ── 1. Ensure JDK 17 is present ───────────────────────────────────────────────
if [ ! -d "$JDK_DIR" ]; then
  echo "Downloading Temurin JDK 17..."
  curl -sL "$JDK_URL" -o /tmp/jdk17.tar.gz
  tar -xzf /tmp/jdk17.tar.gz -C /tmp/
  echo "JDK 17 ready."
fi
export JAVA_HOME="$JDK_DIR"
export PATH="$JAVA_HOME/bin:$PATH"

# ── 2. Ensure Android SDK is present ─────────────────────────────────────────
if [ ! -d "$SDK_DIR/platforms/android-33" ]; then
  echo "Setting up Android SDK..."
  mkdir -p "$SDK_DIR/cmdline-tools"
  curl -sL "$SDK_URL" -o /tmp/cmdline-tools.zip
  unzip -q /tmp/cmdline-tools.zip -d "$SDK_DIR/cmdline-tools"
  mv "$SDK_DIR/cmdline-tools/cmdline-tools" "$SDK_DIR/cmdline-tools/latest" 2>/dev/null || true
  export PATH="$PATH:$SDK_DIR/cmdline-tools/latest/bin"
  yes | sdkmanager --licenses > /dev/null 2>&1
  sdkmanager "platform-tools" "build-tools;33.0.2" "platforms;android-33"
  echo "Android SDK ready."
fi
export ANDROID_SDK_ROOT="$SDK_DIR"
export ANDROID_HOME="$SDK_DIR"
export PATH="$PATH:$SDK_DIR/cmdline-tools/latest/bin:$SDK_DIR/platform-tools"

# ── 3. Build ──────────────────────────────────────────────────────────────────
echo "Building APK..."
./gradlew assembleDebug

APK="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK" ]; then
  echo ""
  echo "✓ Build successful: $APK ($(du -h $APK | cut -f1))"
else
  echo "✗ Build failed — APK not found."
  exit 1
fi
