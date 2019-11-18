#!/bin/bash
# @Author: richard
# @Date:   2017-08-11 17:27:49
# @Last Modified by:   richard
# @Last Modified time: 2017-08-11 18:04:58
#保留近 N 天
KEEP_DAYS=7 
# 删除前 N的所有天到 前N+10天==>每天执行
function get_todelete_days()
{
    # declare -A DAY_ARR
    # DAY_ARR=""
    for i in $(seq 1 10);
    do
        THIS_DAY=$(date -d "$(($KEEP_DAYS+$i)) day ago" +%Y.%m.%d)
 
        DAY_ARR=( "${DAY_ARR[@]}" $THIS_DAY)
    done
    echo ${DAY_ARR[*]} 
}
# 返回数组的写法
TO_DELETE_DAYS=(`get_todelete_days`)
for day in "${TO_DELETE_DAYS[@]}"
do
    echo "$day will be delete"  
    curl -XDELETE 'http://127.0.0.1:9200/*-'${day}
done
