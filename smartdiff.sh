#!/bin/bash
VERSION=0.1.1
REPO='dgilan/smartdiff'
HOMEPATH=$HOME"/.smartdiff"
REVISION_LIST_FILE=$HOMEPATH"/revisions_list.txt"
LOGFILE=$HOMEPATH"/smartdiff.log"
STATUS_FILE=$HOMEPATH"/status.cfg"
DEPS=(
    "git"
    "node"
    "npm"
    "diff2html"
)
FILTER_BY=$2

# --------------- FUNCTIONS ------------------ #
# Adds a message into the logfile
function log() {
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

# Returns current branch name
function current_branch() {
    echo $(git rev-parse --abbrev-ref HEAD)
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

function stash() {
    log "Stashing the working directory"
    git stash &>/dev/null
}

function unstash() {
    stash_list=$(git stash list)
    if [ ! "$stash_list" == '' ]
    then
        log "Unstashing the working directory"
        git stash pop 1>/dev/null
    fi
}

function switch_to_diff_branch() {
    stash
    log "Switching to a new branch $diff_branch"
    git checkout "$1~1" &>/dev/null # checkout one commit before the argument
    git checkout -b "$diff_branch" &>/dev/null
    
}

function switch_to_original_branch() {
    git cherry-pick --abort &>/dev/null
    log "Swithing to the original branch $original_branch"
    git checkout "$original_branch" &>/dev/null
    log "Deleting diff branch: $diff_branch"
    git branch -D "$diff_branch" &>/dev/null
    unstash
}

function get_revisions() {
    log "Filtering git history searching for $FILTER_BY"
    
    found=$(git log --grep=$FILTER_BY --pretty=%h)
    revisions=$(printf '%s\n' "${found[@]}" | tac | tr '\n' ' ')
    set_config 'revisions' $revisions
    echo $revisions
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

# 
function cherry_pick() {
    for ((i=1;i<=$#;i++))
    do
        set_config 'current_ref_index' $i
        log "Cherry-picking ${!i}..."
        git cherry-pick ${!i}
        if [ $? -eq 1 ]
        then
            echo "Resolve conflicts and run the script with --continue flag"
            exit 1
        fi
    done
}

function cherry_pick_continue() {
    parse_config
    refs=($revisions)

    log "Retrying to cherry-pick ${refs[$current_ref_index-1]}"


    git -c core.editor=true cherry-pick --continue
    if [ $? -eq 1 ]
    then
        echo "Resolve conflicts and run the script with --continue flag"
        exit 1
    fi

    for ((i=$current_ref_index;i<${#refs[@]};i++))
    do
        index=$(($i + 1)) # index in cfg starts from 1
        ref=${refs[$index-1]} # index in array starts from 0
        set_config 'current_ref_index' $index
        log "Cherry-picking $ref..."
        git cherry-pick $ref
        if [ $? -eq 1 ]
        then
            echo "Resolve conflicts and run the script with --continue flag"
            exit 1
        fi
    done
}

function get_diff() {
    log "Creating a diff file"
    git diff $1 > /tmp/smartdiff.diff
    diff2html -s side -f html -d word -i file -o preview -- /tmp/smartdiff.diff
}

# Checks that package is installed by running
# $package --version command
# Returns 0 if installed and 1 if not.
function check_package() {
    version=$($1 --version 2>/dev/null || echo "null")
    [[ $version == "null" ]] && echo "1" || echo "0"
}

# Checks the list of packages to be installed
function check_deps() {
    for package in "$@"
    do
        if [ $(check_package $package) == "1" ]
        then
            if [ "$package" == "diff2html" ]
            then
                read -p "Would you like to install $package (Y/n):" -n 1 confirmation

                if [[ "${confirmation:-Y}" =~ ^[Yy]$ ]]
                then
                    echo "Installing $package"
                    npm install -g diff2html-cli
                fi
            else
                echo "Please, install $package first".
            fi
        fi
    done
}

# Checks the latest version and updates package to it
function check_update() {
    latest=$(curl -s https://api.github.com/repos/$REPO/releases/latest | jq .tag_name | sed -En "s/\"v(.*)\"/\1/p")
    if [ "$latest" != "$VERSION" ]
    then
        read -s -rp $'A new version available. Would you like to update? (Y/n)\n' -n 1 confirmation
        if [[ "${confirmation:-Y}" =~ ^[Yy]$ ]]
        then
            curl -o- https://raw.githubusercontent.com/$REPO/v$latest/install.sh 1>/dev/null | bash
            exit 0
        else
            exit 1
        fi
    fi
}

# -------- Checking for updates  ------------- #
check_update

# -------- Checking all dependencies --------- #
dependencies_checks=$(check_deps ${DEPS[@]})

if [ "$dependencies_checks" != "" ]
then
    echo $dependencies_checks
    exit 1
fi

# --------- Running the script ----------------#
case "$1" in
    --version)
        echo "Smart Diff "$VERSION
        exit 0
    ;;
    --filter)
        createDirIfNotExist $HOMEPATH

        if [ -f $STATUS_FILE ]
        then
            parse_config
            clean_up
        fi


        createFileIfNotExist $STATUS_FILE
        original_branch=$(current_branch)
        diff_branch="smart-diff-$FILTER_BY"

        set_config 'original_branch' $original_branch
        set_config 'diff_branch' $diff_branch

        read -a refs <<< "$(get_revisions)"

        root_ref=$(git rev-parse --revs-only ${refs[0]}^1)

        set_config 'root_ref' ${refs[0]}

        switch_to_diff_branch "${refs[0]}"

        cherry_pick "${refs[@]}"
        get_diff $root_ref
        clean_up --force
    ;;
    --abort)
        clean_up --force
    ;;
    --continue)
        if [ ! -f $STATUS_FILE ]
        then
            echo "No smart diff config found to continue"
            exit 1
        fi

        cherry_pick_continue
      
        get_diff $root_ref
        clean_up --force
    ;;
    *)
        cat << EOF
Using: smartdiff --filter CAV-12345

Options: 
    --filter    Selects all revisions by the filter, cherry-picks them and makes diff.
    --version   Prints version
    --continue  Continue cherry-picking once the conflicts resolved
    --abort     Aborts cherry-picking
EOF
    ;;
esac
