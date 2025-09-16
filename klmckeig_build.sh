#!/bin/bash

source klmckeig_config

./configure --enable-debug CFLAGS="-O2 -fno-omit-frame-pointer" --prefix=$install_dir
make -j$(nproc)
make install
cd contrib/pg_prewarm
make
make install
cd ../..
[ -d "$data_dir" ] && rm -rf "$data_dir"
$initdb -D "$data_dir"