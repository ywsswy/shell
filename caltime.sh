#!/bin/bash

function YwsRunTime
{
    begin_time=$1
    begin_s=${begin_time%.*}
    begin_nanos=${begin_time#*.}
    end_time=$2
    end_s=${end_time%.*}
    end_nanos=${end_time#*.}
    if [ "$end_nanos" -lt "$begin_nanos" ];then
        end_s=$(( 10#$end_s - 1 ))
        end_nanos=$(( 10#$end_nanos + 10**9 ))
    fi
    time=$(( 10#$end_s - 10#$begin_s )).`printf "%03d\n" $(( (10#$end_nanos - 10#$begin_nanos)/10**6 ))`
    echo $time
}

ybegin=$(date +"%s.%N")
usleep 500000
yend=$(date +"%s.%N")
ytime=$(YwsRunTime ${ybegin} ${yend})
echo ${ytime}
