#!/bin/bash
SELECTION="(Please choose from the following)"
VALID=0
CHOOSE="*CHOOSE A VALID NUMBER*"
USERNUMBER=("Single User" "Multiple Users")
mapfile -t SINGLE < singleuserlist.txt
mapfile -t MULTI < multiuserlist.txt
mapfile -t HOMEORG < cashomeorglist.txt
mapfile -t ORGNUMS < casorgnums.txt
validateChoice()
{
    #Check for blank input
    if [ -z "$1" ]; then
        echo $CHOOSE
        RESULT="continue"
    else
        if ! [[ "$1" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
        then
            echo $CHOOSE
            RESULT="continue"
        else
            RESULT=""
        fi
    fi
}

echo "How many users use this device? ${SELECTION}"
while [[ $VALID = 0 ]]; do
    HOWMANY=0
    for i in ${!USERNUMBER[@]}; do
        echo "$((i+1)) - "${USERNUMBER[i]}
    done
    read -p "Choose: " HOWMANY
    validateChoice $HOWMANY
    $RESULT
    if [ $HOWMANY = 1 ] || [ $HOWMANY = 2 ]; then
        VALID=1
        USERS=${USERNUMBER[$((HOWMANY-1))]}
    else
        VALID=0
        echo $CHOOSE
    fi
done
VALID=0

echo "How is this computer used? ${SELECTION}"
while [[ $VALID = 0 ]]; do
    HOWUSED=0
    if [[ $HOWMANY = 1 ]]; then
        for i in ${!SINGLE[@]}; do
            echo "$((i+1)) - "${SINGLE[i]}
        done
        LEN=${#SINGLE[@]}
    else
        for i in ${!MULTI[@]}; do
            echo "$((i+1)) - "${MULTI[i]}
        done
        LEN=${#MULTI[@]}
    fi
    echo $LEN
    read -p "Choose: " HOWUSED
    echo $HOWUSED
    if [ $HOWUSED -gt $LEN ] || [ $HOWUSED -lt 1 ]; then
        echo $CHOOSE
        continue
    else
        validateChoice $HOWUSED
        $RESULT
    fi
    if [[ $HOWMANY = 1 ]]; then
        PRIMARYUSE=${SINGLE[$((HOWUSED-1))]}
        VALID=1
    else
        PRIMARYUSE=${MULTI[$((HOWUSED-1))]}
        VALID=1
    fi
    echo $PRIMARYUSE
done
VALID=0

echo "Which Department does this device belong to? ${SELECTION}"
while [[ $VALID = 0 ]]; do
    DEPT=0
    cat cashomeorglist.txt | nl -s "-" -b a | rs -t 0 2
    read -p "Choose: " DEPT
    if [[ $DEPT -gt 65 ]] || [[ $DEPT -lt 1 ]]; then
        echo $CHOOSE
        continue
    else
        validateChoice $DEPT
	$RESULT
        NUMCHOICE=${ORGNUMS[$((DEPT-1))]}
	ORGCHOICE=${HOMEORG[$((DEPT-1))]}
    fi
    VALID=1
done
echo "${ORGCHOICE}"
