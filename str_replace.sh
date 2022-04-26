#!/usr/bin/env bash

if [ "${1+yes}" == "" ];then
    # 允许$1是空字符串，但是不允许$1不传
    echo "WARN unset"
    # 替换为空是被禁止的？
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
            from_str="${from_str//\*/\\*}"
            from_str="${from_str//\./\\.}"
            sed -i "s/${from_str}/${to_str}/g" "$file_name"
            # 如果from_str恰巧包含正则的字符，例如/ * .等，那么sed就会不符合预期，所以把特殊字符转义后再执行sed，确保sed是不含正则的
        fi  
    done
fi
