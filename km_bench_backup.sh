#!/bin/bash

source km_config
mkdir -p $pg_logs_dir

[ -d "$data_dir" ] && rm -rf "$data_dir"
mkdir -p "$data_dir"
$initdb -D "$data_dir" > /dev/null 2>&1

$pg_ctl -D $data_dir -l $pg_log_file start -o "-p $pg_port"

if $psql -p $pg_port -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
    echo "Database $db_name already exists. Dropping and recreating."
    $dropdb $db_name -p $pg_port
fi
$createdb -p $pg_port $db_name
$pgbench -i -s $SCALE_FACTOR -p $pg_port $db_name

taskset -c "$pg_server_pin_core" $pg_ctl -D $data_dir -l $bench_log_file restart -o "-c config_file=$pg_backup_bench_config -p $pg_port"

start=$(date +%s.%N)
size_bytes=$(
$pg_basebackup -X none -P -v -Ft -D - -p $pg_port \
    --compress=none --checkpoint=fast \
    --manifest-checksums=crc32c \
    2> >(tee "$output_log" >&2) | wc -c
)
end=$(date +%s.%N)

$pg_ctl -D $data_dir stop

size_mb=$(echo "scale=2; $size_bytes/1024/1024" | bc)
duration=$(echo "scale=2; $end - $start" | bc)
throughput=$(echo "scale=4; $size_mb / $duration" | bc -l)

target_log_file=$bench_log_file
search_target="pg_comp_crc32c_avx512"
source km_parse_logs_for_checksum_len.sh

headers="run_id,workload,pg_ver,duration(s),throughput(MB/s),scale_factor,backup_size(MB),start_time,end_time,server_cores,client_cores,crc32c_count,crc32c_len,output_log,pg_log,perf_log"
values="$run_id,pg_basebackup,$pg_base,$duration,$throughput,$SCALE_FACTOR,$size_mb,$start,$end,$server_cores,$client_cores,$target_count,$target_avg,$output_log,$pg_log_file,$perf_data"

echo "$headers"
echo "$values"

echo "$headers" >> $result_file
echo "$values" >> $result_file
