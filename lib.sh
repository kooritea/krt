#!/bin/bash

#加载方式
#source /path/lib namespace

# 调试 /bin/bash /path/lib $lib_tag $lib_cmd $arg1 $arg2 $arg3 $arg4 

lib_tag="$1"
lib_cmd="$2"

#调用本库的脚本的位置
lib_runpath=$(cd `dirname $0`; pwd)

#当前库所在的位置
lib_staticpath=$(cd $(dirname ${BASH_SOURCE[0]}); pwd)

#配置文件路径，要写绝对路径，相对路径请使用lib_runpath或lib_staticpath拼接
lib_configpath="$lib_staticpath/lib.env"

# 配置文件可用参数和实例格式
# libenv_mpushurl=(http|https)://[host]:[port]

source "$lib_configpath"

#如果已经锁定则直接退出脚本
lib_checkLock(){
  if [ -e "$lib_runpath/$lib_tag.lock" ];then
	  exit 0
  fi
}
lib_setlock(){
	touch "$lib_runpath/$lib_tag.lock"
}
lib_unlock(){
	rm -rf "$lib_runpath/$lib_tag.lock"
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
  if [ "$scope" == "" ];then
    scope="default"
  fi

  if [ ! -f "$lib_runpath/$scope.accumulative" ];then
    touch "$lib_runpath/$scope.accumulative"
  fi

  local sum=`cat $lib_runpath/$scope.accumulative`
  if [ "$sum" == "" ];then
    sum=0
  fi
  if [ "$lib_cmd" == "add" ];then
    sum=`expr $sum + 1`
    echo "$sum" > "$lib_runpath/$scope.accumulative"
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
  if [ "$lib_cmd" == "reset" ];then
    echo "0" > "$lib_runpath/$scope.accumulative"
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



if [ "$lib_cmd" == "" ];then
  if [ "$lib_tag" == "" ];then
    freelibname="1"
    while [ -d "/tmp/lib-$freelibname" ]
    do
      freelibname=`expr $freelibname + 1`
    done
    lib_tag="lib-$freelibname"
  fi
  if [ ! -d "/tmp/$lib_tag" ];then
    mkdir "/tmp/$lib_tag"
  fi
  lib_runpath="/tmp/$lib_tag"
else
  $lib_cmd $3 $4 $5 $6
fi
