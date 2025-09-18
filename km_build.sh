#!/bin/bash

pwd=$(pwd)
source klmckeig_config
mkdir -p "$install_dir"

./configure --enable-debug CFLAGS="-O2 -fno-omit-frame-pointer" --prefix=$install_dir
make -j50
make install
cd contrib/pg_prewarm
make
make install

[ -d "$data_dir" ] && rm -rf "$data_dir"
$initdb -D "$data_dir" > initdb_output.log 2>&1

cd $pwd