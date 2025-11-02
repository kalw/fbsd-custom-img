#!/bin/env sh

# the directory of the script
DIR="$(cd "$(dirname "$0")" && pwd)"
# the temp directory used, within $DIR
# omit the -p parameter to create a temporal directory in the default location
WORK_DIR=`mktemp -d -p "$DIR"`

# check if tmp dir was created
if [ ! "$WORK_DIR" ] || [ ! -d "$WORK_DIR" ]; then
  echo "Could not create temp dir"
  exit 1
fi
# deletes the temp directory
cleanup() {
  rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}
# register the cleanup function to be called on the EXIT signal
trap 'cleanup' 0

pkg install -y curl

get_all_latest_releases_list() {
  # Fetch all RELEASE directories from FreeBSD amd64 releases page
  curl -s https://download.freebsd.org/releases/amd64/ \
  | awk -F'"' '/href/ && /RELEASE\// {print $4}' \
  | sed -E 's@([0-9.]+)-RELEASE/@\1@' \
  | sort -u \
  | awk '{printf $0","}' \
  | sed -e 's/,$//'
}

get_all_flavors_list() {
  # Fetch all config directories
  find . -type d -depth 1 \
  | sed -e 's/\.\///' -e '/.git/d' \
  | awk '{printf $0","}' |sed -e 's/,$//'
}

# buildin img 
FREEBSD_LATEST_RELEASES=$(get_all_latest_releases_list)
FREEBSD_ARCHS=${FREEBSD_VM_ARCH:-"arm64/aarch64,amd64/amd64"}
FREEBSD_ISO_DL_PATH=${FREEBSD_ISO_DL_PATH:-"${WORK_DIR}"}
FREEBSD_VERSIONS=${FREEBSD_VERSIONS:-"${FREEBSD_LATEST_RELEASES}"}
FREEBSD_FLAVORS=${FREEBSD_FLAVORS:-"$(get_all_flavors_list)"}

for FREEBSD_ARCH  in $(echo ${FREEBSD_ARCHS} | tr ',' ' '); do
  echo "Preparing FreeBSD architecture: ${FREEBSD_ARCH}"
  # var for future utm/qemu work
  # FREEBSD_VM_ARCH=${FREEBSD_VM_ARCH:-"$(echo ${FREEBSD_ARCH} | awk '{print $2}')"}
  # FREEBSD_HDD_SIZE=${FREEBSD_HDD_SIZE:-"65536"}
  # FREEBSD_RAM_SIZE=${FREEBSD_RAM_SIZE:-"4096"}
  for FREEBSD_VERSION in $(echo ${FREEBSD_VERSIONS} | tr ',' ' '); do
    echo "Preparing FreeBSD version: ${FREEBSD_VERSION}"
    FREEBSD_IMG_NAME="FreeBSD-${FREEBSD_VERSION}-RELEASE-$(echo ${FREEBSD_ARCH} |sed -e 's/amd64\/amd64/amd64/' -e 's/\//-/')-mini-memstick.img"
    FREEBSD_ISO_URL="https://download.freebsd.org/releases/${FREEBSD_ARCH}/ISO-IMAGES/${FREEBSD_VERSION}/${FREEBSD_IMG_NAME}"
    curl -o ${FREEBSD_ISO_DL_PATH}/${FREEBSD_IMG_NAME}.xz "${FREEBSD_ISO_URL}.xz" 
    xz -d ${FREEBSD_ISO_DL_PATH}/${FREEBSD_IMG_NAME}.xz
    for FREEBSD_FLAVOR in $(echo $FREEBSD_FLAVORS | tr ',' ' '); do
      mdconfig -u 0 -f ${FREEBSD_ISO_DL_PATH}/${FREEBSD_IMG_NAME}
      mount /dev/md0p2 /mnt
      rm /mnt/etc/installerconfig || true
      cp ./${FREEBSD_FLAVOR}/installerconfig /mnt/etc/installerconfig
      umount /mnt
      mdconfig -du 0

      mkdir -p artifacts
      cp ${FREEBSD_ISO_DL_PATH}/${FREEBSD_IMG_NAME} artifacts/${FREEBSD_FLAVOR}-${FREEBSD_IMG_NAME}
      xz -z -9 artifacts/${FREEBSD_FLAVOR}-${FREEBSD_IMG_NAME}
    done

  done
done
exit 0





# cat << EOF > /tmp/create.utm.vm.applescript
# tell application "UTM"
#     --- specify a boot ISO
#     set iso to POSIX file "${FREEBSD_ISO_DL_PATH}"
#     --- create a new QEMU VM for ${FREEBSD_VM_ARCH} with a single 64GiB drive
#     set vm to make new virtual machine with properties {backend:qemu, configuration:{name:"QEMU ${FREEBSD_VM_ARCH}", architecture:"${FREEBSD_VM_ARCH}", drives:{{removable:true, source:iso}, {guest size:${FREEBSD_HDD_SIZE}}}, memory: ${FREEBSD_RAM_SIZE} , network interfaces:{{mode:bridged}} }}
# end tell
# EOF



