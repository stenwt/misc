#!/usr/bin/env bash

## Simple function to log in a bash script 
function log { 
	[ -z $OUTFILE ] && OUTFILE=${0}.log
  STAMP=$(date +"%Y-%m-%d %H:%M:%S")
  if [ $1 = "error" ]
  then
    echo "$STAMP - ERROR - $2" | tee -a $OUTFILE
		exit 2;
  elif [ $1 = "info" ]
  then
    echo "$STAMP - info - $2" | tee -a $OUTFILE
  elif [ $1 = "debug" ]
  then
    if [ -z $DEBUG ]
    then
      echo "$STAMP - debug - $2" >> $OUTFILE
    else
      echo "$STAMP - debug - $2" | tee -a $OUTFILE
    fi
  else
    echo "$STAMP - ERROR : invalid log level passed to log function: $*" | tee -a $OUTFILE
    exit 2;
  fi
}

