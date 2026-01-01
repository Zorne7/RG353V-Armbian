#!/bin/bash

set -e

# -----------------------------
# CLEAN
# -----------------------------
if [[ "$1" == "clean" ]]; then
    [[ -d "localbuild" ]] && cd localbuild || exit 0

    OIFS="$IFS"
    IFS=$'\n'
    for mp in $(mount | grep "$(pwd)" | cut -d' ' -f3- | sed -E 's|(.*) type .*|\1|'); do
        echo "unbind $mp"
        sudo umount "$mp" || exit 1
    done
    IFS="$OIFS"

    cd ..
    sudo rm -rf localbuild/
    exit 0
fi

# -----------------------------
# PREPARE localbuild/
# -----------------------------
[[ ! -d "localbuild" ]] && mkdir localbuild
cd localbuild

# Unmount previous mounts
OIFS="$IFS"
IFS=$'\n'
for mp in $(mount | grep "$(pwd)" | cut -d' ' -f3- | sed -E 's|(.*) type .*|\1|'); do
    echo "unbind $mp"
    sudo umount "$mp" || exit 1
done
IFS="$OIFS"

# -----------------------------
# FUNCTION: prep Armbian build system
# -----------------------------
prep() {
    echo "prep"
    export LatestArmbianVer=$(gh release list -R armbian/build | grep -v trunk | head -n1 | cut -f1)
    export LatestArmbianURL="https://github.com/armbian/build/archive/refs/tags/${LatestArmbianVer}.tar.gz"
    echo "LatestArmbianURL=$LatestArmbianURL"

    wget -q -nv "$LatestArmbianURL" -O ${LatestArmbianVer}.tar.gz
    tar --strip-components=1 --exclude=.gitignore --exclude=.git --exclude=README.md -xf ${LatestArmbianVer}.tar.gz
    rm -f ${LatestArmbianVer}.tar.gz

    [[ "$1" == "prep" ]] && exit
}

# -----------------------------
# CREATE DIRECTORY STRUCTURE BEFORE BIND
# -----------------------------
echo "[INFO] Creating directory structure for bind mounts..."

for d in config config/boards config/kernel config/sources config/sources/families; do
    [[ ! -d "$d" ]] && mkdir -p "$d"
done

# -----------------------------
# BIND-MOUNT ALL FILES FROM ../userpatches INTO config/
# -----------------------------
echo "[INFO] Bind-mounting userpatches into Armbian tree..."

OIFS="$IFS"
IFS=$'\n'
for f in $(find ../userpatches -type f 2>/dev/null); do
    rel="${f#../userpatches/}"      # strip prefix
    dest="config/$rel"              # Armbian expects them under config/
    mkdir -p "$(dirname "$dest")"
    touch "$dest"
    sudo mount --bind "$f" "$dest"
done
IFS="$OIFS"

# -----------------------------
# RUN PREP IF NEEDED
# -----------------------------
[[ "$1" == "prep" ]] && prep
[[ ! -f "compile.sh" ]] && prep

# -----------------------------
# BUILD IMAGES (Armbian 25.x syntax)
# -----------------------------
now=$(date +%Y%m%d%H%M%S)

if [[ "$1" != "prep" && -n "$1" ]]; then
    echo "making image(s): $@"

    for i in $@; do

        # Parse preset: rg353v-bookworm-minimal
        BOARD=$(echo $i | cut -d- -f1)
        RELEASE=$(echo $i | cut -d- -f2)
        TYPE=$(echo $i | cut -d- -f3)

        if [[ "$TYPE" == "minimal" ]]; then
            BUILD_MINIMAL=yes
            BUILD_DESKTOP=no
        else
            BUILD_MINIMAL=no
            BUILD_DESKTOP=yes
        fi

        rm -rf output/logs

        ./compile.sh \
            BOARD=$BOARD \
            RELEASE=$RELEASE \
            BUILD_MINIMAL=$BUILD_MINIMAL \
            BUILD_DESKTOP=$BUILD_DESKTOP

        img=$(find output -name "Armbian-*_${BOARD}_*.img")
        log=$(find output -name log-build-*.log)
        id=$(echo $log | sed -E 's|.*log-build-(.*)\.log|\1|')

        outdir=../localoutput/$now/$BOARD/$RELEASE/$TYPE
        mkdir -p "$outdir"

        mv "$img" $outdir/armbian-${i}.img
        mv "$img.sha" $outdir/armbian-${i}.img.sha
        mv "$img.txt" $outdir/armbian-${i}.img.txt
        mv "output/logs/log-build-$id.log" $outdir/armbian-${i}-build.log
        mv "output/logs/log-docker-$id.log" $outdir/armbian-${i}-docker.log
        mv "output/logs/summary-build-$id.md" $outdir/armbian-${i}-build.summary
        mv "output/logs/summary-docker-$id.md" $outdir/armbian-${i}-docker.summary
    done
else
    ls ../userpatches/config-*-* | cut -d'-' -f2-4 | cut -d'.' -f1
fi

# -----------------------------
# FINAL UNBIND
# -----------------------------
OIFS="$IFS"
IFS=$'\n'
for mp in $(mount | grep "$(pwd)" | cut -d' ' -f3- | sed -E 's|(.*) type .*|\1|'); do
    sudo umount "$mp" && rm "$mp" || exit 1
done
IFS="$OIFS"

