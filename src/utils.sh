function gnu_sed() {
    if [ "$(uname)" == "Darwin" ]
    then
        echo $(gsed ${@})
    else
        echo $(sed ${@})
    fi
}

# Add logs to the logfile
function log() {
    # TODO: do we need tee here?
    echo -e $(date +"%Y-%m-%d %H:%M:%S") $1 | tee -a $LOGFILE 1>/dev/null
}

function createDirIfNotExist() {
    if [ ! -d $1 ]
    then
        log "Creating directory $1."
        mkdir $HOMEPATH
    fi
}

function createFileIfNotExist() {
    if [ ! -f $1 ]
    then
        log "Creating file $1."
        touch $1
    fi
}

# Parses config files and injects its values as variables
function parse_config() {
    log "Reading config file: $STATUS_FILE"
    cat $STATUS_FILE | cut -d"=" -s -f1,2 > /tmp/tmp.config
    source /tmp/tmp.config
}

# Sets a value to the config
function set_config() {
    key=$1
    values="${@:2}"
    as_string="\"${values[*]}\""
    
    log "Set config value: $key=$values"
    echo -e "$key=$as_string" >> $STATUS_FILE
}

# Checks out to the original branch and removes all temporary files.
function clean_up() {
    if [ -f $STATUS_FILE ]
    then
        if [ ! "$1" == "--force" ]
        then
            read -s -rp $'Are you sure you want to abort previous smartdiff? (y/N)\n' -n 1 confirmation
            if [[ ! "${confirmation:-N}" =~ ^[Yy]$ ]]
            then
                echo "Try running 'smartdiff --continue'."
                exit 1
            fi
        fi
        parse_config
        switch_to_original_branch
        rm $STATUS_FILE
        rm $LOGFILE
    fi
}

function print_conflict_message() {
    echo "Resolve conflicts and run the script with --continue flag"
}

# Thats the point the whole script was created about!
function get_diff() {
    log "Creating a diff file"
    git diff $1 > /tmp/smartdiff.diff
    log "Creating a template"
    echo 'FilteringBy: '$FILTER_BY
    echo $HTML_TEMPLATE | gnu_sed "s/<\!\-\-smartdiff\-filter\-by\-\->/$FILTER_BY/" > /tmp/html_template.html

    diff2html -s side -f html -d word -i file -o preview --hwt /tmp/html_template.html -- /tmp/smartdiff.diff
}

# diff2html -s side -f html -d word -i file -o preview --hwt ./ui.html -- /tmp/smartdiff.diff