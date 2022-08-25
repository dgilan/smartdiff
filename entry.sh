#!/bin/bash

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

source $SCRIPTPATH/src/config.sh
source $SCRIPTPATH/src/deps.sh
source $SCRIPTPATH/src/utils.sh
source $SCRIPTPATH/src/updates.sh
source $SCRIPTPATH/src/git_utils.sh
source $SCRIPTPATH/src/run.sh
