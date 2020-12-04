#!/usr/bin/env bash

if [ "${1+yes}" == "" ];then
    echo "WARN unset"
    while LFS= ;read -r line;do
        :
    done
else
    to_str="${1//\//\\/}"
    while LFS= ;read -r line;do
        echo -e "$line"
        file_name=$(echo -en "$line" |awk -v FS="\x1b\\\[K|\x1b\\\[m\x1b\\\[K" -v OFS="_" '{$1=$1; print $2}')
        from_str=$(echo -en "$line" |awk -v FS="\x1b\\\[K|\x1b\\\[m\x1b\\\[K" -v OFS="_" '{$1=$1; print $10}')
        if [ "$from_str" != ""\
            -a "$file_name" != "" ];then
            from_str="${from_str//\//\\/}"
            sed -i "s/${from_str}/${to_str}/g" "$file_name"
        fi  
    done
fi
