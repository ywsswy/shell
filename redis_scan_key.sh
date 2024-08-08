#!/usr/bin/env bash

# 需要修改的地方是redis的地址 & cmd_file文件中写密码 & scan的个数和总数 & match命令
# cmd_file的格式是
# ```
# auth <pwd>
# CMD
# ```
# TODO: 已知问题,如果each_count设置得过小可能该次scan不到,后面处理没考虑这种异常

gEnableLogLevelVec=(
"DEBUG"
"INFO0"
"ERROR"
)

function GetOS() {
  os="$(uname)"
  if [ "$os" = "Darwin" ];then
    echo -n "mac"
  else
    echo -n "linux"
  fi
}

function HashGet() {
  res=$(GetOS)
  if [ "$res" = "mac" ];then
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
  # pstree -p $$ |awk -F 'sh\\(' 'BEGIN{RS=")"}{if(NF==2) printf("%s ",$2)}' |xargs kill -9
  $(YLog "$1" ERROR "${*:2}")
  kill 0
  sleep 1
  kill -9 0
}


get_cursor="0"
each_count=10
count=0
myIFS=$(echo -ne "\x0a\x0d")
for ((;;))do
	cmd=$(echo -n "scan ${get_cursor} match * count ${each_count}")
	mv cmd_file.bak cmd_file
	sed -i.bak -r s/CMD/"${cmd}"/g cmd_file
	script -e -q -c "cat cmd_file |redis-cli -c -h <ip> -p <port>" /dev/null >res_file </dev/null
	i=0
	while OLDIFS=${IFS}; IFS=${myIFS}; read -r line; ret=$?; IFS=${OLDIFS}; [ $ret -eq 0 ];do  #这个IFS置空，否则read line会把行首行尾的空白字符忽略掉的~，while的IFS变量会影响整个文件，所以放到函数局部中
		i=$((i+1))
		#echo "line:${line}"
		if [ $i -eq 1 ];then
			if [ "${line}" != "OK" ];then
				echo "res_file err:${line}"
				$(KillScript)
			fi
		elif [ $i -eq 2 ];then
			# get cursor
			get_cursor=$(echo -ne "${line}" |perl -pe 's|.*?"(.*)".*?|\1|')
			if [ "${get_cursor}" = "${line}" ];then
				echo "get_cursor line err:${line}"
				$(KillScript)
			fi
		else
			# get key
			get_key=$(echo -ne "${line}" |perl -pe 's|.*?"(.*)".*?|\1|')
			if [ "${get_key}" = "${line}" ];then
				echo "get_key line err:${line}"
				$(KillScript)
			fi
			echo "${get_key}"
		fi
	done < res_file
	if [ "${get_cursor}" = "0" ];then
		break
	fi
	count=$((count + i - 2))
	if [ $count -gt 30 ];then
		break
	fi
done
