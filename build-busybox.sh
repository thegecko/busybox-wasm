#!/bin/bash

SRC=$(dirname $0)

BUILD="$1"
BUSY_SRC="$2"

if [ "$BUILD" == "" ]; then
    BUILD=$(pwd)/build
fi  

if [ "$MPY_SRC" == "" ]; then
    BUSY_SRC=$(pwd)/build/busybox
fi


if [ ! -d $BUSY_SRC/ ]; then
    git clone --depth 1 git://busybox.net/busybox.git "$BUSY_SRC/"

    pushd $BUSY_SRC/

    # This is the last tested commit of busybox.
    COMMIT=1a64f6a20aaf6ea4dbba68bbfa8cc1ab7e5c57c4
    git fetch origin $COMMIT
    git reset --hard $COMMIT

    # Fetch submodules
    git submodule update --init

    popd
fi

SRC=$(realpath "$SRC")
BUILD=$(realpath "$BUILD")

pushd $BUSY_SRC/

mkdir -p arch/em

# This is a config containing just "tar" and "xz -d". 
# I imagine most of busybox should work, but we dont need it here.
cp $SRC/patches/.config $BUSY_SRC

# Generate an override Makefile.
echo 'cmd_busybox__ = $(CC) -o $@.mjs \
     -Wl,--start-group \
     -s LLD_REPORT_UNDEFINED=1 \
     -s ALLOW_MEMORY_GROWTH=1 \
     -s EXPORTED_FUNCTIONS=_main,_free,_malloc \
     -s EXPORTED_RUNTIME_METHODS=FS,PROXYFS,ERRNO_CODES,allocateUTF8 \
     -lproxyfs.js \
     --js-library=../../emlib/fsroot.js \
     -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
     -Oz $(CFLAGS) $(CFLAGS_busybox) $(LDFLAGS) $(EM_LDFLAGS) $(EXTRA_LDFLAGS) \
     $(core-y) $(libs-y) $(patsubst %,-l%,$(subst :, ,$(LDLIBS))) \
     -Wl,--end-group && cp $@.mjs $@' > arch/em/Makefile

# Symlink emgcc to emcc, add to current PATH.
ln -s $(which emcc.py) emgcc || true
export PATH=$BUSY_SRC:$PATH

make ARCH=em CROSS_COMPILE=em SKIP_STRIP=y

popd
