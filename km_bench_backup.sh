#!/bin/bash

source km_config
mkdir -p $pg_logs_dir

$pg_ctl -D $data_dir -l $pg_log_file start -o "-p $pg_port"

if $psql -p $pg_port -lqt | cut -d \| -f 1 | grep -qw "$db_name"; then
    echo "Database $db_name already exists. Dropping and recreating."
    $dropdb $db_name
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

headers="run_id,pg_ver,use_crc32c_avx512,duration(s),throughput(MB/s),scale_factor,backup_size(MB),start_time,end_time,output_log,pg_log,perf_log"
values="$run_id,$pg_base,$USE_AVX512_CRC32C_BUILD,$duration,$throughput,$SCALE_FACTOR,$size_mb,$start,$end,$output_log,$pg_log_file,$perf_data"

echo "$headers"
echo "$values"

echo "$headers" >> $result_file
echo "$values" >> $result_file
