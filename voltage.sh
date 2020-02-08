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

    for id in core sdram_c sdram_i sdram_p ; do
    	#echo -e "$id:\t $(vcgencmd measure_volts $id)" ;
    	IFS='='
    	tmp=$(vcgencmd measure_volts $id)
    	read -ra RET <<< "$tmp"
	if [ "$id" == "core" ]; then
		CORE_VOLT=${RET[1]}
		CORE_VOLT=${CORE_VOLT:0:6}
    	    	echo -n "   "$CORE_VOLT"|COR=${RET[1]}"
	fi
	if [ "$id" == "sdram_c" ]; then
		SDRC_VOLT=${RET[1]}
		SDRC_VOLT=${SDRC_VOLT:0:6}
	    	echo -n "   "$SDRC_VOLT"|SRC=${RET[1]}"
	fi
	if [ "$id" == "sdram_i" ]; then
		SDRI_VOLT=${RET[1]}
		SDRI_VOLT=${SDRI_VOLT:0:6}
	    	echo -n "   "$SDRI_VOLT"|SRI=${RET[1]}" 
	fi
	if [ "$id" == "sdram_p" ]; then
		SDRP_VOLT=${RET[1]}
		SDRP_VOLT=${SDRP_VOLT:0:6}
	    	echo -n "   "$SDRP_VOLT"|SRP=${RET[1]}" 
	fi
    done
    TOTAL=$(($CORE_VOLT = $SDRC_VOLT))
    echo "total="$TOTAL
    sleep 5s 
done
