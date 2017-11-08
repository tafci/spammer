#! /bin/bash

echo -n "Naplófájl elérési újta: "
read FILE

echo -n > tmp
echo -n > out

while read LINE ; do
    YEAR=2017
    MON=$(echo $LINE | cut -d' ' -f1) 
    DAY=$(echo $LINE | cut -d' ' -f2)
    TIME=$(echo $LINE | cut -d' ' -f3)

    case $MON in
        Jan) MON=01 ;;
        Feb) MON=02 ;;
        Mar) MON=03 ;;
        Apr) MON=04 ;;
        May) MON=05 ;;
        Jun) MON=06 ;;
        Jul) MON=07 ;;
        Aug) MON=08 ;;
        Sep) MON=09 ;;
        Oct) MON=10 ;;
        Nov) MON=11 ;;
        Dec) MON=12 ;;
    esac

    echo "$LINE $(date -d"${YEAR}-${MON}-${DAY} ${TIME}" +"%s")" >> tmp
done <<< "$(cat $FILE)" 

sort tmp -k4 -k5 > ./sorted
echo "end" >> sorted

ID_CURR=$(head -n 1 ./sorted | cut -d' ' -f4)
ID_NEXT=
TS_CURR=$(head -n 1 ./sorted | cut -d' ' -f5)
TS_NEXT=
DATE=
CNTR=1
while read LINE ; do
    ID_NEXT=$(echo $LINE | cut -d' ' -f4)
    TS_NEXT=$(echo $LINE | cut -d' ' -f5)

    if [ "$(echo $LINE | cut -d' ' -f1)" != "end" ] ; then
        DATE="$(echo $LINE | cut -d' ' -f1) $(echo $LINE | cut -d' ' -f2) $(echo $LINE | cut -d' ' -f3)"
    fi

    if [ "$ID_NEXT" == "$ID_CURR" ] && [ "$TS_NEXT" == "$TS_CURR" ] ; then 
        CNTR=$((CNTR + 1))
    else 
        echo $DATE $ID_CURR $CNTR >> out

        CNTR=1
        ID_CURR=$ID_NEXT
        TS_CURR=$TS_NEXT
    fi 
done <<< "$(tail -n +2 ./sorted)"

rm ./tmp
rm ./sorted