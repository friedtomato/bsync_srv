#!/bin/bash

# script source
SCR_DNAME=$BSYNC_SCR_PATH
SCR_FNAME=bsync_srv.pl
COM_FNAME=file_cli.pl
INS_FNAME=instr
WIF_FNAME=wsync_srv.pl
STA_FNAME=status_aut.sh
LOGI_FNAME=output_instr.log
LOGS_FNAME=output_srv.log
LOGW_FNAME=output_wif.log
SCR_FULL=$SCR_DNAME/$SCR_FNAME
COM_FULL=$SCR_DNAME/$COM_FNAME
INS_FULL=$SCR_DNAME/$INS_FNAME
WIF_FULL=$SCR_DNAME/$WIF_FNAME
LOGI_FULL=$SCR_DNAME/$LOGI_FNAME
LOGS_FULL=$SCR_DNAME/$LOGS_FNAME
LOGW_FULL=$SCR_DNAME/$LOGW_FNAME
STA_FULL=$SCR_DNAME/$STA_FNAME


# display and perl modules dir
export DISPLAY=:0
export PERL5LIB=$SCR_DNAME

if [ "$BSYNC_RUN" == "r" ]; then
	# run status collector
	echo "running status collector"
	$STA_FULL &
	# run server
  	if [ "$BSYNC_MOD" == "a" ]; then 
		if [ "$BSYNC_LOG" == "r" ]; then
			echo "running bsync server in auto mode with logging"
			$SCR_FULL auto 2>&1 | tee $LOGS_FULL &
			sleep 3
  			$COM_FULL $INS_FULL 2>&1 | tee $LOGI_FULL &
		fi
		if [ "$BSYNC_LOG" == "n" ]; then
			echo "running bsync server in auto mode without logging"
			$SCR_FULL auto &
			sleep 3
  			$COM_FULL $INS_FULL &
		fi
  	fi
  	if [ "$BSYNC_MOD" == "m" ]; then
		if [ "$BSYNC_LOG" == "r" ]; then
			echo "running bsync server in manual mode with logging"
			$SCR_FULL 2>&1 | tee $LOGS_FULL &
		fi
		if [ "$BSYNC_LOG" == "n" ]; then
			echo "running bsync server in manual mode without logging"
			$SCR_FULL &
		fi
	fi
	# run wifi server
  	if [ "$BSYNC_WIF" == "r" ]; then
		if [ "$BSYNC_LOG" == "r" ]; then
			echo "running wifi server with logging $WIF_FULL on $LOGW_FULL"
			sleep 3
			$WIF_FULL 2>&1 | tee $LOGW_FULL &
		fi
		if [ "$BSYNC_LOG" == "n" ]; then
			echo "running wifi server without logging"
			sleep 3
			$WIF_FULL &
		fi
	fi
fi

