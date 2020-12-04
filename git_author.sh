#!/usr/bin/env bash

arr=($(ls -la |awk -v FS=" " -v OFS="_" '{$1=$1; printf $9; printf "\n"}'))
for ((i = 0; i < ${#arr[*]}; ++i))do
    res=$(git log ${arr[$i]} |head -3 |grep "Author" |awk -v FS=" " -v OFS="_" '{$1=$1; print $2}')
    echo -e "${res:0:7}\t\t${arr[$i]}"
done
