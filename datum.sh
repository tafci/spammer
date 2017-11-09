#! /bin/bash

# Naplófájl elérési útjának bekérése
echo -n "Naplófájl elérési újta: "
read FILE

# Köztes fájlok létrehozása
echo -n > tmp # Egyet mert valahol tárolni akarjuk az átalakított dátumokat
echo -n > out # Egyet mert valahol a timestampek és proc id-k alapján rendezett adatokat akarjuk tárolni

# Eredeti logfájl feldolozása, a benne levő dátumokból timestamp generálása
while read LINE ; do
    YEAR=2017                               # Mivel a logfájl nem tartalmaz évszámot, feltételezzük, hogy 2017-es logfile
    MON=$(echo $LINE | cut -d' ' -f1)       # Hónap felolvasása
    DAY=$(echo $LINE | cut -d' ' -f2)       # Nap felolvasása
    TIME=$(echo $LINE | cut -d' ' -f3)      # Óra:Perc felolvasása

    # Hónap átalakítása kétszámjegyű formatáumra szövegesről
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

    # Átalakított log rekord kiírása köztes fájlba
    echo "$LINE $(date -d"${YEAR}-${MON}-${DAY} ${TIME}" +"%s")" >> tmp
# Log fájl felolvasása. Azért így, mert a while ciklus így nem egy subshellben fog futni és külső változókat is képes módosítani
# úgy, hogy azoknak az értéke a ciklus futása után is megmaradjon, azok értékei ne csak a cikluson belül legyenek elérhetőek. 
done <<< "$(cat $FILE)" 

# Köztes fájl rendezése és egy záró sor hozzáfűzése, hogy a következő ciklus helyesen dolgozza fel 
# az adatoka. Ha az utolsó sort nem adnánk hozzá, akkor az utolsó proc id sora annak előfordulásaival
# nem íródna ki, mivel nem futna le a feltétel azon része.
sort tmp -k4 -k5 > ./sorted
echo "end" >> sorted

# Változó inicializációk
ID_CURR=$(head -n 1 ./sorted | cut -d' ' -f4) # Rendezett rekordok 1. sorának feldolgozása; 1. sorban levő proc. id felolvasása
ID_NEXT=                                      # Következő proc. id tárolására
TS_CURR=$(head -n 1 ./sorted | cut -d' ' -f5) # Rendezett rekordok 1. sorának feldolgozása; 1. sorban levő timestamp felolvasása
TS_NEXT=                                      # Következő timestamp tárolására
DATE=       # Kiírandó, felhasználó barát formátumú dátum tárolására használt változó
CNTR=1      # Pric ID számláló. 1-től indul
while read LINE ; do
    ID_NEXT=$(echo $LINE | cut -d' ' -f4)   # Következő proc. id felolvasása
    TS_NEXT=$(echo $LINE | cut -d' ' -f5)   # Következő timestamp felolvasása

    # Mivel a sorted köztes állomány utolsó sorába beszúrtunk egy lezáró sort azt nem szabad feldolgozni, így ha
    # odajututnk, hogy az adott sor első eleme az "end" szócska akkor nem generálunk új dátumot, az előzőleg 
    # összeállítottat használjuk.
    if [ "$(echo $LINE | cut -d' ' -f1)" != "end" ] ; then
        # Egyszerűen felolvassuk a hónap, nap, idő értékeket
        DATE="$(echo $LINE | cut -d' ' -f1) $(echo $LINE | cut -d' ' -f2) $(echo $LINE | cut -d' ' -f3)"
    fi

    if [ "$ID_NEXT" == "$ID_CURR" ] && [ "$TS_NEXT" == "$TS_CURR" ] ; then 
        # Ha az elsőnek megfogott sorban levő proc id és timestamp egyezik a másodszorra megfogott sorban
        # levő adatokkal akkor növeljük a számlálót
        CNTR=$((CNTR + 1))
    else 
        # Ha az elsőnek megfogott sorban levő proc id és timestamp nem egyezik meg a következő iterációban
        # feldolgozandó sorban levő értékekkel akkor ez azt jelenti, hogy vagy új proc id vagy egy későbbi 
        # dátum szerepel a következő sorban, így ameddig eljutottunk azt kiírjuk az eredmény fájlba.
        echo $DATE $ID_CURR $CNTR >> out

        # Kiírás után újrainicializáljuk a szükséges változóinkat
        CNTR=1              # Számláló visszaállítása alapértékre
        # Mivel az aktuális iterációban felolvasott sor már más érétkeket tartalmazott ezért ezek az értékek
        # fogják képzeni az összehasonlítás alapját, ezekhez az értékekhez fogjuk a következő iterációkban fel-
        # olvasandó sorok értékeit hasonlítani amíg nem találunk eltérő értékeket.
        ID_CURR=$ID_NEXT
        TS_CURR=$TS_NEXT
    fi 
done <<< "$(tail -n +2 ./sorted)" # Rendezett rekordok felolvasása a 2. sortól kezdve

# Köztes fájlok törlése
rm ./tmp
rm ./sorted