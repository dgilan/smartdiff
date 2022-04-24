#!/bin/bash

VERSION=0.0.1
BIN_PATH=$HOME/.local/bin
FULL_PATH=$BIN_PATH/smartdiff

if [ -f $FULL_PATH ]
then
    rm $FULL_PATH
fi

curl https://raw.githubusercontent.com/dgilan/smartdiff/v$VERSION/smartdiff.sh > $BIN_PATH/smartdiff
chmod +x $FULL_PATH