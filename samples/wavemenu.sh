#!/bin/bash
# This script taking care of the certificate needed for WAVEWebServer and WAVEBackgroundServices
# The options are:
# 1. In fresh installation of WAVE
#    1. Creating a self sign certificate, and show the user where the certificate is, so it can
#       be copied and install in his windows machine.
#    2. Ask the user to provide his own certificate, and add it to the keystore.
#    3. In case the user cant install on his windows the self signed certificate, let the user
#       change the WAVE.jnlp file.
# 2. In migration, we backup the old certificate and use it and show the user where the
#    certificate is, so it can be copied and install in his windows machine.
# 3. It will run also as an external tool to manage certificates, and to make the needed change
#    in the WAVE.jnlp file in case the user deside not to use certificate.
function yesno() {
    #example: yesno "Save settings y/n?" "Yy"
    read -p "$1 [$2] :" answer
    if [[ "$answer" =~ ^["$2"] ]]; then
        return 0
    fi
    return 1
}

function maxLength() {
    max_length=0
    for element in "$@}"; do
        # Find the length of each string
        length=${#element}
        # Compare the length with the current maximum length
        if ((length > max_length)); then
            max_length=$length
        fi
    done
    echo "$max_length"
}

function blueLogMessagePadded() {
    #example of call: blueLogMessagePadded 80 $str
    local slen=$1
    local str=$2
    spaces=$(printf ' %.0s' {1..100})
    spaces=${spaces::slen}
    stLength=${#str}
    echo -e "$bgBlue$fgWhite${spaces:1:3}$str${spaces:1:slen-stLength}$fgDefault"
}

function printBlueBlock() {
    #example of call: printBlueBlock 80 "${MigrationWarn[@]}"
    local slen=$1
    shift
    local txt=("$@")
    local slen
    slen=$(maxLength "${txt[@]}")
    ((slen += 3))
    #spaces=$(printf ' %.0s' {1..100})
    spaces=$(printf '%*s' 100)
    spaces=${spaces::slen}
    for line in "${txt[@]}"; do
        line=" $line"
        stLength=${#line}
        echo -e "${spaces:1:2}$bgBlue$fgWhite${spaces:1:3}$line${spaces:1:slen-stLength}$fgDefault"
    done
}

function topline() {
    printf "$st$upperLeftCorner"
    for i in {1..90}; do
        printf "$horizontalLine"
    done
    printf "$upperRightCorner$en\n"
}

function undertitleline() {
    printf "$st$LeftVerticalSplit"
    for i in {1..90}; do
        printf "$horizontalLine"
    done
    printf "$rightVerticalSplit$en\n"
}

function botline() {
    printf "$st$lowerLeftCorner"
    for i in {1..90}; do
        printf "$horizontalLine"
    done
    printf "$lowerRightCorner$en\n"
}

function mklinefull() {
    s="$2"
    se=$((s + 90))
    if [ ${#3} -gt 0 ]; then
        p3=$3"                                                                            "
        pe=${p3:0:87}
        printf "${1:0:s}$pe${1:$se}"
    fi
}

function mkline() {
    s=$2
    se=$((s + 38))
    if [ ${#3} -gt 0 ]; then
        p3=$3"                                                                 "
        pe=${p3:0:38}
        printf "${1:0:s}$pe${1:$se}"
    fi
}
function midlinefull() {
    p1=$1

    p1n=${#p1}

    #echo $p1n $p2n
    line=$(printf ' %.0s' {1..90})
    if [ $p1n -gt 0 ]; then
        line=$(mklinefull "$line" 3 "$1")
    fi
    printf "$st$verticalLine$line$verticalLine$en\n"
}
function midline() {
    p1=$1
    p2=$2
    p1n=${#p1}
    p2n=${#p2}
    #echo $p1n $p2n
    line=$(printf ' %.0s' {1..90})
    if [ $p1n -gt 0 ]; then
        line=$(mkline "$line" 3 "$1")
    fi
    if [ $p2n -gt 0 ]; then
        line=$(mkline "$line" 48 "$2")
    fi
    printf "$st$verticalLine$line$verticalLine$en\n"
}

function doproccess() {
    #echo "doProccess: $1" ${Menu[$1]}
    #for key in "${!Menu[@]}"; do
    # echo $key  ${Menu[$key]}
    #done
    if [ ! -z "$1" ]; then
        first="${Menu[$1]#*@}"
        #echo "Doing $first"
        $first
    fi
}

mkspace() {
    if ((${#1} == 1)); then
        echo "  "
    else
        echo " "
    fi
}

function pmenu() {
    declare -A Menu
    OMenu=()
    i=0
    for line in "$@"; do
        #echo "option=$line"
        #echo ${line#*=}
        if [ "$i" -eq 0 ]; then
            mfunc=${line#*@}
            title="${line%%@*}"
        else
            Menu[${line%%=*}]=${line#*=}
            OMenu[$i]=${line%%=*}
        fi
        ((i++))
    done

    if [ $batch -eq 0 ]; then
        while :; do # Loop forever
            topline
            if [ "$mfunc" != "$title" ]; then
                $mfunc
            fi
            midlinefull "$title $chHead"
            undertitleline
            #set -x
            lb=${#OMenu[@]}
            if [ $((lb % 2)) -eq 0 ]; then
                l=$(($lb / 2))
            else
                l=$(($lb / 2 + 1))
            fi
            #set +x
            i=1
            while [ $i -lt $(($l + 1)) ]; do
                entry=${OMenu[$i]}
                if (((i + l) <= lb)); then
                    entry2=${OMenu[$(($i + l))]}
                    midline "$entry.$(mkspace $entry)${Menu[$entry]%%@*}" "$entry2.$(mkspace $entry2)${Menu[$entry2]%%@*}"
                else
                    midline "$entry.$(mkspace $entry)${Menu[$entry]%%@*}"
                fi
                i=$(($i + 1))
            done
            botline
            echo -e -n "$st Your choice? : $en"
            read choise
            doproccess $choise
        done
    else
        batch=0
        doproccess $choise
    fi

    #doproccess $choise

}
quit() {
    exit 0
}
LANG=en_US.utf-8
LC_ALL=en_US.utf-8
export LC_CTYPE="UTF-8"
st="\E[33;44m\033[1m"
en="\033[0m"
# Colors for messages
fgDefault="\033[0m" # AKA reset
fgGreen="\e[32m"
fgYellow="\e[33m"
fgRed="\e[31m"
# WAVE-65
bgRed="\033[41m"
bgGreen="\033[42m"
bgBlue="\033[44m"
fgWhite="\033[1;37m"

themecode=1
case $themecode in # Check number of arguments
        1)
st=$fgYellow$bgBlue
upperLeftCorner='\u250C'
upperRightCorner='\u2510'
lowerLeftCorner='\u2514'
lowerRightCorner='\u2518'
horizontalLine='\u2500'
verticalLine='\u2502'
rightVerticalSplit='\u2524'
LeftVerticalSplit='\u251c'
;;
    2)
#st="\E[33;44m\033[1m"
st=$fgWhite$bgBlue
horizontalLine='\u2550'     # ═        U+2550
verticalLine='\u2551'       # ║        U+2551
upperLeftCorner='\u2554'    # ╔        U+2554
upperRightCorner='\u2557'   # ╗        U+2557
lowerLeftCorner='\u255a'    # ╚        U+255a
lowerRightCorner='\u255d'   # ╝        U+255d
LeftVerticalSplit='\u2560'  # ╠        U+2560
rightVerticalSplit='\u2563' # ╣        U+2563
# ╒        U+2552
# ╓        U+2553
# ╕        U+2555
# ╖        U+2556
# ╘        U+2558
# ╙        U+2559
# ╛        U+255b
# ╜        U+255c
# ╞        U+255e
# ╟        U+255f
# ╡        U+2561
# ╢        U+2562
# ╤        U+2564
# ╥        U+2565
# ╦        U+2566
# ╧        U+2567
# ╨        U+2568
# ╩        U+2569
# ╪        U+256a
# ╫        U+256b
# ╬        U+256c
;;
*)
            echo theamcode is wrong $themecode
            exit
            ;;
    esac


batch=0
if [ "$1" != "" ]; then
    batch=1
    choise=$1
fi
