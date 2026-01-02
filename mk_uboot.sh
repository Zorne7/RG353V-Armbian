#!/bin/bash

set -eu

ArmbianVer=v25.11.1

export ArmbianURL=https://github.com/armbian/build/archive/refs/tags/${ArmbianVer}.tar.gz
echo ArmbianURL=$ArmbianURL
rm -r armbian || echo ""
mkdir armbian
cd armbian
wget -q -nv "$ArmbianURL" -O${ArmbianVer}.tar.gz
tar --strip-components=1 --exclude=.gitignore --exclude=.git --exclude=README.md -xf ${ArmbianVer}.tar.gz
rm -f ${ArmbianVer}.tar.gz
