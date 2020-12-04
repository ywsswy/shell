#!/usr/bin/env bash


if [ $# -ne 1 ];then
    echo "para 0"
    exit 1
fi
l=`ps xf |grep $1 |grep -v $0 |grep -v grep |awk '{printf("%s\n", $1)}'`
if [ "$l" = "" ];then
    echo "no such pro"
    exit 1
fi
echo $l
kill $l
