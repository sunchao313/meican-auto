#!/bin/bash

TODAY=$(date +"%Y-%m-%d")
CUR_TIMESTAMP=$(($(date +%s%N)/1000000))

BREAKFIRST_IDX=0    #2
LUNCH_IDX=1         #0
DINNER_IDX=2        #1

CORP_ADDR_ID="e704d4144cc8"
USER_ADDR_ID="e704d4144cc8"

ACCEPT_LANG="Accept-Language: en-US,en;q=0.8,da;q=0.6,ja;q=0.4,ko;q=0.2,zh-CN;q=0.2,zh;q=0.2,zh-TW;q=0.2,fr;q=0.2"
ACCEPT_ENCODING="Accept-Encoding: gzip, deflate, sdch, br"
UA="User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/56.0.2924.87 Safari/537.36"
ACCEPT="Accept: application/json, text/plain, */*"

COOKIE=""

TARGET_TIMES=("+20:30" "+10:00" "+16:00")

fire_req()
{
    curl -s "$1" -H "$ACCEPT_ENCODING" -H "$ACCEPT_LANG" -H "$UA" -H "$ACCEPT" -H 'Referer: https://meican.com/' -H "$COOKIE" -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' --compressed
}

query_tab_uniqueid()
{
    # 0=>2
    # 1=>0
    # 2=>1
    fanfan_type=$1
    type=$(echo "($fanfan_type+2)%3" | bc)

    fire_req "https://meican.com/preorder/api/v2.1/calendarItems/list?beginDate=$TODAY&endDate=$TODAY&noHttpGetCache=$CUR_TIMESTAMP&withOrderDetail=false" \
    | jq -r '.dateList|.[0].calendarItemList|.['$type'].userTab.uniqueId'
}

list_restaurant()
{
    fire_req "https://meican.com/preorder/api/v2.1/restaurants/list?noHttpGetCache=$CUR_TIMESTAMP&tabUniqueId=$1&targetTime=$TODAY$2" \
    | jq -r '.restaurantList[] | select (.name | contains("比萨") | not) | .uniqueId'
}

list_dishes()
{
    read rest_id
    fire_req "https://meican.com/preorder/api/v2.1/restaurants/show?noHttpGetCache=$CUR_TIMESTAMP&restaurantUniqueId=$rest_id&tabUniqueId=$1&targetTime=$TODAY$2" \
    | jq -r '.sectionList[0].dishIdList[]'
}

submit_order()
{
    read dish_id
    curl -s "https://meican.com/preorder/api/v2.1/orders/add?corpAddressUniqueId=$CORP_ADDR_ID&order=%5B%7B%22count%22:1,%22dishId%22:$dish_id%7D%5D&tabUniqueId=$1&targetTime=$TODAY$2&userAddressUniqueId=$USER_ADDR_ID" -X POST -H "$ACCEPT_ENCODING" -H "$ACCEPT_LANG" -H "$UA" -H "$ACCEPT" -H 'Referer: https://meican.com/' -H "$COOKIE" -H 'Connection: keep-alive' -H 'Cache-Control: max-age=0' --compressed | jq -r .status
}

fanfan()
{
    fanfan_type=$1
    target_time=${TARGET_TIMES[$fanfan_type]}
    tab_uniq_id=$(query_tab_uniqueid $fanfan_type)

    list_restaurant $tab_uniq_id $target_time | shuf -n1 \
    | list_dishes $tab_uniq_id $target_time | shuf -n1 \
    | submit_order $tab_uniq_id $target_time
}

# breakfast 0
# lunch     1
# dinner    2
fanfan $1
exit 0


#* 20 * * 1,2,3,4,7 sh fanfan.sh 0 1>/dev/null
#* 9 * * 1-5 sh fanfan.sh 1 1>/dev/null
#* 15 * * 1-5 sh fanfan.sh 2 1>/dev/null
