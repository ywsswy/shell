#!/usr/bin/env bash

str="$1"
# chinese all
type="$2"

function UrlEncode()
{
    for ((i = 0; i < ${#1}; ++i))do
        chr=${1:i:1}
        ascii_code=$(printf "%d" "'$chr ")
        if [ "$2" == "all" ];then
          echo -n "$chr" |hexdump -C |awk -v FS="  " '{printf $2;}' |awk -v FS=" " -v OFS="%%" '{$1=$1; printf "%%";printf $0;}'
        else
          if [ $ascii_code -gt 255 ];then
              echo -n "$chr" |hexdump -C |awk -v FS="  " '{printf $2;}' |awk -v FS=" " -v OFS="%%" '{$1=$1; printf "%%";printf $0;}'
          else
              echo -n "$chr"
          fi
        fi
    done
}

echo -n $(UrlEncode $str $type)
