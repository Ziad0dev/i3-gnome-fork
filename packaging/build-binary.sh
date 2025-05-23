#!/bin/bash
#
# build-binary.sh - Build a self-contained binary installer for i3-gnome
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="/tmp/i3-gnome-binary-build"
VERSION=$(grep 'VERSION =' "$PROJECT_DIR/Makefile" | cut -d'=' -f2 | tr -d ' ')

echo "Building i3-gnome binary installer version $VERSION"

# Create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/i3-gnome-$VERSION"

# Copy source files
cp -r "$PROJECT_DIR"/* "$BUILD_DIR/i3-gnome-$VERSION/"
rm -rf "$BUILD_DIR/i3-gnome-$VERSION/.git" "$BUILD_DIR/i3-gnome-$VERSION/dist"

# Create installer script
cat > "$BUILD_DIR/installer.sh" << 'EOF'
#!/bin/bash

# Self-extracting installer for i3-gnome
# Generated by build-binary.sh

INSTALLER=`basename "$0"`
VERSION="__VERSION__"
ARCHIVE_OFFSET="__ARCHIVE_OFFSET__"
TEMP_DIR="/tmp/i3-gnome-installer-$USER"

echo "i3-gnome Self-Extracting Installer (v$VERSION)"
echo "------------------------------------------------"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root to install"
  exit 1
fi

# Extract archive
echo "Extracting files..."
mkdir -p "$TEMP_DIR"
tail -n +$ARCHIVE_OFFSET "$0" | tar xzf - -C "$TEMP_DIR"

# Install
echo "Installing i3-gnome..."
cd "$TEMP_DIR/i3-gnome-$VERSION"
make install

# Cleanup
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Installation complete!"
echo "To use i3-gnome, log out and select 'I3 + GNOME' from the login screen."
exit 0
EOF

# Replace version placeholder
sed -i "s/__VERSION__/$VERSION/g" "$BUILD_DIR/installer.sh"

# Make it executable
chmod +x "$BUILD_DIR/installer.sh"

# Create tarball
cd "$BUILD_DIR"
tar -czf "archive.tar.gz" "i3-gnome-$VERSION"

# Get line count of installer script
LINES=$(wc -l < "$BUILD_DIR/installer.sh")
ARCHIVE_OFFSET=$((LINES + 1))

# Replace archive offset placeholder
sed -i "s/__ARCHIVE_OFFSET__/$ARCHIVE_OFFSET/g" "$BUILD_DIR/installer.sh"

# Create self-extracting archive
cat "$BUILD_DIR/installer.sh" "$BUILD_DIR/archive.tar.gz" > "$PROJECT_DIR/dist/i3-gnome-$VERSION.run"
chmod +x "$PROJECT_DIR/dist/i3-gnome-$VERSION.run"

echo "Binary installer created at dist/i3-gnome-$VERSION.run" 