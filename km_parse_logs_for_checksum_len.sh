#!/bin/bash

target_count=0
target_avg=0
nums=$(grep "LOG:  \[${search_target}\] len=" "$target_log_file" | sed -n "s/.*LOG:  \[${search_target}\] len=\([0-9]*\).*/\1/p")
sum=0

for n in $nums; do
    sum=$((sum + n))
    target_count=$((target_count + 1))
done

if [ "$target_count" -eq 0 ]; then
    echo "No matching lines found."
else
    target_avg=$(echo "scale=2; $sum / $target_count" | bc)
fi

echo target_count=$target_count
echo target_avg=$target_avg
