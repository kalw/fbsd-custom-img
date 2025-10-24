#!/bin/env sh

# the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
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

# start script
FREEBSD_LATEST_RELEASE=$(curl -s https://download.freebsd.org/releases/amd64/ | awk '{print $3}' | grep RELEASE | tr -d '"' | tr -d '/' | cut -f2 -d'=' | sort | tail -1 |sed -e 's/-RELEASE//')
FREEBSD_ARCH=${FREEBSD_VM_ARCH:-"arm64/aarch64"}
FREEBSD_VM_ARCH=${FREEBSD_VM_ARCH:-"$(echo ${FREEBSD_ARCH} | awk '{print $2}')"}
FREEBSD_ISO_DL_PATH=${FREEBSD_ISO_PATH:-"${WORK_DIR}"}
FREEBSD_VERSION=${FREEBSD_VERSION:-"${FREEBSD_LATEST_RELEASE}"}
FREEBSD_IMG_NAME="FreeBSD-${FREEBSD_VERSION}-RELEASE-$(echo ${FREEBSD_ARCH} |sed -e 's/\//-/')-mini-memstick.img"
FREEBSD_ISO_URL=${FREEBSD_ISO_URL:-"https://download.freebsd.org/releases/${FREEBSD_ARCH}/ISO-IMAGES/${FREEBSD_VERSION}/${FREEBSD_IMG_NAME}"}
FREEBSD_HDD_SIZE=${FREEBSD_HDD_SIZE:-"65536"}
FREEBSD_RAM_SIZE=${FREEBSD_RAM_SIZE:-"4096"}
FREEBSD_FLAVOR=${FREEBSD_FLAVOR:-"poudriere"}

cd ${FREEBSD_ISO_DL_PATH} && { fetch -o ${FREEBSD_IMG_NAME} "${FREEBSD_ISO_URL}" ; cd -; }

ls /dev/md*
mdconfig -u 0 -f ${FREEBSD_ISO_DL_PATH}/${FREEBSD_IMG_NAME}
ls /dev/md*
mount /dev/md0p2 /mnt
cp ./${FREEBSD_FLAVOR}-install/installerconfig /mnt/etc/installerconfig
umount /mnt
mdconfig -du 0

mkdir -p artifacts
mv ${FREEBSD_ISO_DL_PATH}/${FREEBSD_IMG_NAME} artifacts/${FREEBSD_FLAVOR}-${FREEBSD_IMG_NAME}
if [ "$CIRRUS_BRANCH" = "main" ]; then
  echo "releasing"
  pkg install -y gh cocogitto
  git config --global user.name "release-bot"
  git config --global user.email "release-bot@ci.net"
  for flavor in desktop poudriere; do
    if cog bump --auto --package ${flavor}-install; then
      VERSION=$(cog get-version --package ${flavor}-install)
      echo "Version: ${VERSION}"
      gh release create "${flavor}-v${VERSION}" \
        --title "${flavor} v${VERSION}" \
        --notes "$(cog changelog --at ${flavor}-install/v${VERSION})" \
        artifacts/${FREEBSD_FLAVOR}-${FREEBSD_IMG_NAME}
    fi
  done
fi

# cat << EOF > /tmp/create.utm.vm.applescript
# tell application "UTM"
#     --- specify a boot ISO
#     set iso to POSIX file "${FREEBSD_ISO_PATH}"
#     --- create a new QEMU VM for ${FREEBSD_VM_ARCH} with a single 64GiB drive
#     set vm to make new virtual machine with properties {backend:qemu, configuration:{name:"QEMU ${FREEBSD_VM_ARCH}", architecture:"${FREEBSD_VM_ARCH}", drives:{{removable:true, source:iso}, {guest size:${FREEBSD_HDD_SIZE}}}, memory: ${FREEBSD_RAM_SIZE} , network interfaces:{{mode:bridged}} }}
# end tell
# EOF



