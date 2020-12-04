#!/usr/bin/env bash
# * * * * * sh ~/workspace/github.com/ywsswy/shell/crontab_new.sh >>~/.crontab_new.log 2>&1
# TODO: 可重入

if [ `basename $0` != 'bashdb' ];then
  arg0=$0
else
  arg0=$1
  shift
fi
if [ -f ~/.bash_profile ];then
  . ~/.bash_profile
fi

gEnableLogLevelVec=(
"DEBUG"
"INFO0"
"INFO1"
"ERROR"
)

function GetOS() {
  os="$(uname)"
  if [ "$os" == "Darwin" ];then
    echo -n "mac"
  else
    echo -n "linux"
  fi
}

function HashGet() {
  res=$(GetOS)
  if [ "$res" == "mac" ];then
    md5hash=$(echo -n "$1" |md5)
  else
    md5hash=$(echo -n "$1" |md5sum)
  fi
  echo $((16#${md5hash:0:15}))
}

gEnableLogLevelMapk=()

for ((i = 0; i < ${#gEnableLogLevelVec[*]}; ++i))do
  hash_index=$(HashGet "${gEnableLogLevelVec[$i]}")
  gEnableLogLevelMapk[${hash_index}]="${gEnableLogLevelVec[$i]}"
done

function YLog() {
  # $1: $LINENO
  # $2: debug level, DEBUG,INFO0,INFO1,INFO2,WARN,ERROR
  if [ "${gDisableLogLevelCheck+set}" != "" ];then
    echo "$(date +"%Y-%m-%d %H:%M:%S") [$2]: [$arg0:$1]:${*:3}" >&2
  else
    hash_index=$(HashGet "$2")
    if [ "${gEnableLogLevelMapk[${hash_index}]+set}" != "" ];then
      echo "$(date +"%Y-%m-%d %H:%M:%S") [$2]: [$arg0:$1]:${*:3}" >&2
    fi
  fi
}

function KillScript() {
  $(YLog "$1" ERROR "${*:2}")
  kill 0
  sleep 1
  kill -9 0
}

function RunCmd() {
    realcal_timestamp="$2"
    #echo "$1" |awk -v FS=" " -v OFS="_" '{$1="";$2="";$3="";$4="";$5="";printf $0;printf NF}' >&2
    start_min="$(echo "$1" |awk -v FS=" " '{printf $1}')"
    start_hour="$(echo "$1" |awk -v FS=" " '{printf $2}')"
    start_day="$(echo "$1" |awk -v FS=" " '{printf $3}')"
    start_mon="$(echo "$1" |awk -v FS=" " '{printf $4}')"
    start_year="$(echo "$1" |awk -v FS=" " '{printf $5}')"
    inter_min="$(echo "$1" |awk -v FS=" " '{printf $6}')"
    inter_hour="$(echo "$1" |awk -v FS=" " '{printf $7}')"
    inter_day="$(echo "$1" |awk -v FS=" " '{printf $8}')"
    res=$(GetOS)
    if [ "$res" == "mac" ];then
      cmd="date -j -f \"%Y-%m-%d %H:%M:%S\" \"$start_year-$start_mon-$start_day $start_hour:$start_min:00\" \"+%s\""
    else
      cmd="date +%s -d\"$start_year-$start_mon-$start_day $start_hour:$start_min:00\""
    fi
    start_timestamp=$(eval $cmd)
    res=$(YLog $LINENO DEBUG "start_timestamp:$start_timestamp")
    if [ $realcal_timestamp -lt $start_timestamp ];then
        res=$(YLog $LINENO INFO0 "not yet start:$1")
    else
        inter_timestamp=$(($inter_min *60+ $inter_hour *60*60+ $inter_day *60*60*24))
        res=$(YLog $LINENO DEBUG "inter_timestamp:$inter_timestamp")
        diff_timestamp=$(($realcal_timestamp - $start_timestamp))
        res=$(YLog $LINENO DEBUG "diff_timestamp:$diff_timestamp")
        diff_remainder=$(($diff_timestamp % $inter_timestamp))
        res=$(YLog $LINENO DEBUG "diff_remainder:$diff_remainder")
        if [ $diff_remainder -ne 0 ];then
            res=$(YLog $LINENO INFO0 "not yet trigger:$1")
        else
            res=$(YLog $LINENO INFO0 "OK")
            pre="$start_min $start_hour $start_day $start_mon $start_year $inter_min $inter_hour $inter_day "
            res=$(YLog $LINENO DEBUG "pre:$pre")
            suffix="${1//"$pre"/}"
            res=$(YLog $LINENO DEBUG "suffix:$suffix")
            res=$(GetOS)
            if [ "$res" == "mac" ];then
              cmd="date -j -f %s $realcal_timestamp"
            else
              cmd="date -d @$realcal_timestamp"
            fi
            trigger_time="$(eval $cmd)"
            res=$(YLog $LINENO INFO1 "($trigger_time) $1")
            res=$(eval "source ~/.bashrc; $suffix")
        fi
    fi
    
}

function Main() {
    arr=(
        '0 0 2 10 2020 0 0 2 echo "Today mom is at home."'
    )

    now_timestamp=$(date +%s)
    res=$(YLog $LINENO INFO0 "now_timestamp:$now_timestamp")
    remainder=$(($now_timestamp % 60))
    realcal_timestamp=$(($now_timestamp - $remainder))
    res=$(YLog $LINENO INFO0 "realcal_timestamp:$realcal_timestamp")

    for ((i = 0; i < ${#arr[*]}; ++i))do
        res=$(YLog $LINENO INFO0 "cmd:${arr[$i]}")
        res="$(RunCmd "${arr[$i]}" "$realcal_timestamp")"
    done
}

res=$(Main)
