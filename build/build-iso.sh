#!/bin/bash
# RebuiltTux 2 ISO build starter
# Creates a minimal bootable ISO using available Linux ISO tools.

set -e

BUILD_DIR="$(pwd)/build/work"
ISO_DIR="$BUILD_DIR/iso"
OUTPUT="rebuilttux2.iso"

mkdir -p "$ISO_DIR/boot/grub"

cat > "$ISO_DIR/README.txt" <<EOF
RebuiltTux 2 boot image

This is the first generated ISO foundation.
EOF

cat > "$ISO_DIR/boot/grub/grub.cfg" <<EOF
set timeout=5
set default=0

menuentry "RebuiltTux 2" {
    echo "Welcome to RebuiltTux 2"
    echo "Desktop and installer integration coming next"
}
EOF

if command -v grub-mkrescue >/dev/null 2>&1; then
    grub-mkrescue -o "$OUTPUT" "$ISO_DIR"
else
    echo "grub-mkrescue is not installed. Creating ISO directory only."
fi

echo "Build finished: $OUTPUT"
