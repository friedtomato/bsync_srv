#!/bin/bash

#STAT_DNAME=/home/pi/bin
SCR_DNAME=$BSYNC_SCR_PATH
STAT_DNAME=$SCR_DNAME/log
STAT_FNAME=status
STAT_FULL=$STAT_DNAME/$STAT_FNAME
echo "status_aut: "$STAT_FULL

#Flag Bits
UNDERVOLTED=0x1
CAPPED=0x2
THROTTLED=0x4
SOFT_TEMPLIMIT=0x8
HAS_UNDERVOLTED=0x10000
HAS_CAPPED=0x20000
HAS_THROTTLED=0x40000
HAS_SOFT_TEMPLIMIT=0x80000

#Text Colors
#GREEN=`tput setaf 2`
#RED=`tput setaf 1`
#NC=`tput sgr0`

#Output Strings
#GOOD="${GREEN}NO${NC}"
#BAD="${RED}YES${NC}"

GOOD="NO"
BAD="YES"

while [ true ]; do

    awk -v stat_full="$STAT_FULL" '/^Revision/ {sub("^1000", "", $3); printf "REV="$3 > stat_full}' /proc/cpuinfo

    for id in core sdram_c sdram_i sdram_p ; do
    	#echo -e "$id:\t $(vcgencmd measure_volts $id)" ;
    	IFS='='
    	tmp=$(vcgencmd measure_volts $id)
    	read -ra RET <<< "$tmp"
	if [ "$id" == "core" ]; then
    	    echo -n "|COR=${RET[1]}" >> $STAT_FULL
	fi
	if [ "$id" == "sdram_c" ]; then
	    echo -n "|SRC=${RET[1]}" >> $STAT_FULL
	fi
	if [ "$id" == "sdram_i" ]; then
	    echo -n "|SRI=${RET[1]}" >> $STAT_FULL
	fi
	if [ "$id" == "sdram_p" ]; then
	    echo -n "|SRP=${RET[1]}" >> $STAT_FULL
	fi
    done

    echo -n "|STL=60.0'C" >> $STAT_FULL
    echo -n "|HTL=82.0'C" >> $STAT_FULL
    IFS='='
    tmp=$(vcgencmd measure_temp)
    read -ra RET <<< "$tmp"
    echo -n "|TMP=${RET[1]}" >> $STAT_FULL


    #Get Status, extract hex
    STATUS=$(vcgencmd get_throttled)
    STATUS=${STATUS#*=}

    echo -n "|THRSta=" >> $STAT_FULL
    (($STATUS!=0)) && echo -n "${STATUS}" >> $STAT_FULL || echo -n "${STATUS}" >> $STAT_FULL

    echo -n "|UVOAct=" >> $STAT_FULL
    ((($STATUS&UNDERVOLTED)!=0)) && echo -n "${BAD}" >> $STAT_FULL || echo -n "${GOOD}" >> $STAT_FULL
    echo -n "|UVORun=" >> $STAT_FULL
    ((($STATUS&HAS_UNDERVOLTED)!=0)) && echo -n "${BAD}" >> $STAT_FULL || echo -n "${GOOD}" >> $STAT_FULL

    echo -n "|THRAct=" >> $STAT_FULL
    ((($STATUS&THROTTLED)!=0)) && echo -n "${BAD}" >> $STAT_FULL || echo -n "${GOOD}" >> $STAT_FULL
    echo -n "|THRRun=" >> $STAT_FULL
    ((($STATUS&HAS_THROTTLED)!=0)) && echo -n "${BAD}" >> $STAT_FULL || echo -n "${GOOD}" >> $STAT_FULL

    echo -n "|FCAAct=" >> $STAT_FULL
    ((($STATUS&CAPPED)!=0)) && echo -n "${BAD}" >> $STAT_FULL || echo -n "${GOOD}" >> $STAT_FULL
    echo -n "|FCARun=" >> $STAT_FULL
    ((($STATUS&HAS_CAPPED)!=0)) && echo -n "${BAD}" >> $STAT_FULL || echo -n "${GOOD}" >> $STAT_FULL

    echo -n "|STLAct=" >> $STAT_FULL
    ((($STATUS&SOFT_TEMPLIMIT)!=0)) && echo -n "${BAD}" >> $STAT_FULL || echo -n "${GOOD}" >> $STAT_FULL
    echo -n "|STLRun=" >> $STAT_FULL
    ((($STATUS&HAS_SOFT_TEMPLIMIT)!=0)) && echo "${BAD}" >> $STAT_FULL || echo "${GOOD}" >> $STAT_FULL


    sleep 5s 
done
