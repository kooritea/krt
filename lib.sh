#!/bin/sh

#加载方式
#source /path/lib $namespace $lib_configpath

#持久化文件的前缀
lib_namespace="$1"

#配置文件路径，要写绝对路径，默认"$lib_runpath/lib.env"
#配置文件可用参数和实例格式
#libenv_mpushurl=(http|https)://[host]:[port]
lib_configpath="$2"

# lib_requires=("curl")
lib_requires="curl"
#调用本库的脚本的位置
lib_runpath=$(cd `dirname $0`; pwd)

#临时文件存放路径，在lib_init中初始化
lib_tmppath=""

#当前库所在的位置
# lib_staticpath=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)
#sh环境不可用

lib_init(){
  if [ "$lib_namespace" = "" ];then
    local freelibname="1"
    while [ -d "/tmp/lib-$freelibname" ]
    do
      freelibname=`expr $freelibname + 1`
    done
    lib_namespace="lib-$freelibname"
  fi
  if [ ! -d "/tmp/$lib_namespace" ];then
    mkdir "/tmp/$lib_namespace"
  fi
  lib_tmppath="/tmp/$lib_namespace"

  if [ "$lib_configpath" = "" ];then
    lib_configpath="$lib_runpath/lib.env"
  fi
  if [ -f "$lib_configpath" ];then
    source "$lib_configpath"
  else
    echo "[warn]未找到配置文件： $lib_configpath"
  fi

  for cmd in ${lib_requires};do
    type "$cmd" > /dev/null 2>&1
    if [ $? -ne 0 ];then
      echo "未找到依赖命令： $cmd"
      exit
    fi
  done
}
lib_init

#如果已经锁定则直接退出脚本
lib_checkLock(){
  if [ -e "$lib_tmppath/$lib_namespace.lock" ];then
	  exit 0
  fi
}
lib_setlock(){
	touch "$lib_tmppath/$lib_namespace.lock"
}
lib_unlock(){
	rm -rf "$lib_tmppath/$lib_namespace.lock"
}
#计数器，第一个参数是[add|reset],第二个参数是累计次数,第三个参数是作用域
#返回三种状态码，0,1,2,3
#case $? in
#0)
#  echo "表示0状态未发生改变，可能是add但未到次数，也可能是上次并未到达警告值就已经reset"
#  ;;
#1)
#  echo "表示状态从超过计数限制后使用reset重置"
#  ;;
#2)
#  echo "表示本次add后超过了设定限制次数"
#  ;;
#3)
#  echo "表示上一次已经超过了限制次数，这次依然超过限制次数"
#  ;;
#esac
lib_accumulative(){

  local lib_cmd="$1"
  local limit="$2"
  local scope="$3"
  if [ "$scope" = "" ];then
    scope="default"
  fi

  if [ ! -f "$lib_tmppath/$scope.accumulative" ];then
    touch "$lib_tmppath/$scope.accumulative"
  fi

  local sum=`cat $lib_tmppath/$scope.accumulative`
  if [ "$sum" = "" ];then
    sum=0
  fi
  if [ "$lib_cmd" = "add" ];then
    sum=`expr $sum + 1`
    echo "$sum" > "$lib_tmppath/$scope.accumulative"
    if [ "$sum" -gt "$limit" ];then
      local tmpsum=`expr $sum - 1`
      if [ "$tmpsum" -gt "$limit" ];then
        return 3
      else
        return 2
      fi
    else
      return 0
    fi
  fi
  if [ "$lib_cmd" = "reset" ];then
    echo "0" > "$lib_tmppath/$scope.accumulative"
    if [ "$sum" -gt "$limit" ];then
      return 1
    else
      return 0
    fi
  fi
}

# $1 send/group
# $2 name
# $3 text
# $4 desp
lib_mpush(){
  curl -G "$libenv_mpushurl/$2.$1" --data-urlencode "text=$3" --data-urlencode "desp=$4" > /dev/null
}

# 测试$1中是否存在$2
# 0表示存在
# if [ 0 -eq $? ];then
# else
# fi
lib_strTest(){
	if [ `echo "$1" | grep -c "$2"` -ne 0 ];then
		return 0
	else
		return 1
	fi
}