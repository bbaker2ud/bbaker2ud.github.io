#!/bin/bash
SELECTION="(Please choose from the following)"
VALID=0
CHOOSE="*CHOOSE A VALID NUMBER*"
USERNUMBER=("Single User" "Multiple Users")
mapfile -t SINGLE < /root/singleuserlist
mapfile -t MULTI < /root/multiuserlist
mapfile -t HOMEORG < /root/cashomeorglist
mapfile -t ORGNUMS < /root/casorgnums

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
VALID=0
echo "How many users use this device? ${SELECTION}"
while [[ $VALID = 0 ]]; do
    for i in ${!USERNUMBER[@]}; do
        echo "$((i+1)) - "${USERNUMBER[i]}
    done
    read -p "Choose: " HOWMANY
    validateChoice $HOWMANY
    $RESULT
    if [[ $HOWMANY = 1 ]]; then
        VALID=1
        USERS="${USERNUMBER[$((HOWMANY-1))]}"
        echo "${USERS}"
        echo "Who is the primary user of this device? (Enter the UD id of the user)"
        read -p "UD id: " USERID
        elif [[ $HOWMANY = 2 ]]; then
        VALID=1
        USERS="S{USERNUMBER[$((HOWMANY-1))]}"
        echo "${USERS}"
    else
        echo $CHOOSE
        continue
    fi
done
VALID=0
while [[ $VALID = 0 ]]; do
    echo "How is this device used? ${SELECTION}"
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
    read -p "Choose: " HOWUSED
    if [ $HOWUSED -gt $LEN ] || [ $HOWUSED -lt 1 ]; then
        echo $CHOOSE
        continue
    else
        validateChoice $HOWUSED
        $RESULT
    fi
    if [[ $HOWMANY = 1 ]]; then
        PRIMARYUSE="${SINGLE[$((HOWUSED-1))]}"
        VALID=1
    else
        PRIMARYUSE="${MULTI[$((HOWUSED-1))]}"
        VALID=1
    fi
done
VALID=0
echo "Which Department does this device belong to? ${SELECTION}"
while [[ $VALID = 0 ]]; do
    cat cashomeorglist | nl -s "-" -b a | rs -t 0 2
    read -p "Choose: " DEPT
    if [[ $DEPT -gt 65 ]] || [[ $DEPT -lt 1 ]]; then
        echo $CHOOSE
        continue
    else
        validateChoice $DEPT
        $RESULT
        DEPTCHOICE="${ORGNUMS[$((DEPT-1))]} - ${HOMEORG[$((DEPT-1))]}"
        echo $DEPTCHOICE
    fi
    VALID=1
done
VALID=0
while [[ $VALID = 0 ]]; do
    echo "Which building is this device located in? (Please type the building name) "
    read -p "Building Name: " BUILDING
    if [[ -z "$BUILDING" ]]; then
        echo "**PLEASE ENTER A BUILDING NAME**"
        continue
    else
        VALID=1
    fi
    VALID=1
done
VALID=0
while [[ $VALID = 0 ]]; do
    echo "Which room in ${BUILDING} is this device located? (Please type the room number) "
    read -p "Room Number: " ROOM
    if [[ -z "$ROOM" ]]; then
        echo "**PLEASE ENTER A ROOM NUMBER**"
        continue
    else
        VALID=1
    fi
    VALID=1
done
VALID=0
while [[ $VALID = 0 ]]; do
    echo "Please enter the Asset Tag Number of this device: "
    read -p "Asset Tag Number: " ASSET
    if [[ -z "$ASSET" ]]; then
        echo "**PLEASE ENTER A TAG NUMBER**"
        continue
    else
        VALID=1
    fi
    VALID=1
done
VALID=0
touch description
echo "Device "$(lshw -C SYSTEM | grep version) > description &&
echo "CPU "$(lscpu | grep 'Model name:') >> description &&
echo "Memory "$(dmidecode -t memory | grep Size:) >> description &&
echo "Disk "$(lshw -C disk | grep description:) >> description &&
echo "Disk "$(lshw -C disk | grep size:) >> description &&
echo -e "${USERS};\n${USERID};\n${PRIMARYUSE};\n${DEPTCHOICE};\n${BUILDING};\n${ROOM};\n${ASSET};\n$(cat description)" > guacd.info
