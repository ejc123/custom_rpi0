#!/bin/sh

set -e

# Create the fwup ops script to handling MicroSD/eMMC operations at runtime
# NOTE: revert.fw is the previous, more limited version of this. ops.fw is
#       backwards compatible.
mkdir -p $TARGET_DIR/usr/share/fwup
$HOST_DIR/usr/bin/fwup -c -f $NERVES_DEFCONFIG_DIR/fwup-ops.conf -o $TARGET_DIR/usr/share/fwup/ops.fw
ln -sf ops.fw $TARGET_DIR/usr/share/fwup/revert.fw

# Copy the fwup includes to the images dir
cp -rf $NERVES_DEFCONFIG_DIR/fwup_include $BINARIES_DIR

# Use files-to-cpio.sh from nerves_initramfs to prep config and revert.fw
$BINARIES_DIR/file-to-cpio.sh "$NERVES_DEFCONFIG_DIR/nerves_initramfs.conf" "$BINARIES_DIR/nerves_initramfs.conf.cpio"
$BINARIES_DIR/file-to-cpio.sh "$TARGET_DIR/usr/share/fwup/revert.fw" "$BINARIES_DIR/revert.fw.cpio"
