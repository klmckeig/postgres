#!/bin/bash

target_count=0
target_avg=0

# Initialize group counters
count_lt_1024=0
count_1024_4096=0
count_4097_8192=0
count_8193_16384=0
count_16385_32767=0
count_32768=0
count_gt_32768=0

echo target_log_file=$target_log_file
echo search_target=$search_target

nums=$(grep "LOG:  \[${search_target}\] len=" "$target_log_file" | sed -n "s/.*LOG:  \[${search_target}\] len=\([0-9]*\).*/\1/p")
sum=0
for n in $nums; do
    sum=$((sum + n))
    target_count=$((target_count + 1))
    if [ "$n" -lt 1024 ]; then
        count_lt_1024=$((count_lt_1024 + 1))
    elif [ "$n" -le 4096 ]; then
        count_1024_4096=$((count_1024_4096 + 1))
    elif [ "$n" -le 8192 ]; then
        count_4097_8192=$((count_4097_8192 + 1))
    elif [ "$n" -le 16384 ]; then
        count_8193_16384=$((count_8193_16384 + 1))
    elif [ "$n" -le 32767 ]; then
        count_16385_32767=$((count_16385_32767 + 1))
    elif [ "$n" -eq 32768 ]; then
        count_32768=$((count_32768 + 1))
    else
        count_gt_32768=$((count_gt_32768 + 1))
    fi
done

if [ "$target_count" -eq 0 ]; then
    echo "No matching lines found."
else
    target_avg=$(echo "scale=2; $sum / $target_count" | bc)
fi

echo target_count=$target_count
echo target_avg=$target_avg

echo "<1024: $count_lt_1024"
echo "1024-4096: $count_1024_4096"
echo "4097-8192: $count_4097_8192"
echo "8193-16384: $count_8193_16384"
echo "16385-32767: $count_16385_32767"
echo "32768: $count_32768"
echo ">32768: $count_gt_32768"