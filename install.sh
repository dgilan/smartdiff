#!/bin/bash

VERSION=0.2.7

if [ -d $HOME/.local/bin ]
then
    BIN_PATH=$HOME/.local/bin
else
    BIN_PATH=/usr/local/bin  
fi

FULL_PATH=$BIN_PATH/smartdiff

if [ -f $FULL_PATH ]
then
    rm $FULL_PATH
fi

curl https://raw.githubusercontent.com/dgilan/smartdiff/v$VERSION/smartdiff.sh > $BIN_PATH/smartdiff
curl https://raw.githubusercontent.com/dgilan/smartdiff/v$VERSION/ui.html > $HOME/.smartdiff/ui.html
chmod +x $FULL_PATH