#!/bin/bash

#加载方式
#source /path/lib namespace

tag="$1"
cmd="$2"

if [ "$tag" == "" ];then
  freelibname="1"
  while [ -d "/tmp/lib-$freelibname" ]
  do
    freelibname=`expr $freelibname + 1`
  done
  tag="$freelibname"
fi
if [ ! -d "/tmp/krtlib-$tag" ];then
  mkdir "/tmp/krtlib-$tag"
fi
basepath="/tmp/krtlib-$tag"

#如果已经锁定则直接退出脚本
checkLock(){
  if [ -e "$basepath/$tag.lock" ];then
	  exit 0
  fi
}
setlock(){
	touch "$basepath/$tag.lock"
}
unlock(){
	rm -rf "$basepath/$tag.lock"
}
#计数器，第一个参数是[add|reset],第二个参数是累计次数
#返回三种状态码，0,1,2,3
#case $? in
#0)
#  echo "表示0状态未发生改变，本次是0，上一次也是0"
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
accumulative(){

  if [ ! -f "$basepath/$tag.accumulative" ];then
    touch "$basepath/$tag.accumulative"
  fi

  local cmd="$1"
  local limit="$2"
  local sum=`cat $basepath/$tag.accumulative`
  if [ "$sum" == "" ];then
    sum=0
  fi
  if [ "$cmd" == "add" ];then
    sum=`expr $sum + 1`
    echo "$sum" > "$basepath/$tag.accumulative"
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
  if [ "$cmd" == "reset" ];then
    echo "0" > "$basepath/$tag.accumulative"
    if [ "$sum" -gt "$limit" ];then
      return 1
    else
      return 0
    fi
  fi
}

if [ "$cmd" != "" ];then
  $cmd
fi
