VERSION=0.2.0
REPO='dgilan/smartdiff'
HOMEPATH=$HOME"/.smartdiff"
REVISION_LIST_FILE=$HOMEPATH"/revisions_list.txt"
LOGFILE=$HOMEPATH"/smartdiff.log"
STATUS_FILE=$HOMEPATH"/status.cfg"
FILTER_BY=$2
DEPS=(
    "git"
    "jq"
    "node"
    "npm"
    "diff2html"
)
