#!/bin/bash

pwd=$(pwd)
source km_config
mkdir -p "$install_dir"

./configure --enable-debug CFLAGS="-O2 -fno-omit-frame-pointer" --prefix=$install_dir
make -j50 && make install
cd contrib/pg_prewarm
make && make install

cd $pwd

[ -d "$data_dir" ] && rm -rf "$data_dir"
mkdir -p "$data_dir"
$initdb -D "$data_dir" > /dev/null 2>&1

