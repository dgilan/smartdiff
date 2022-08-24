#!/bin/bash
HTML_TEMPLATE="\<\!DOCTYPEhtml\>\<htmllang=\"en\"\>\<head\>\<metacharset=\"UTF-8\"\>\<metahttp-equiv=\"X-UA-Compatible\"content=\"IE=edge\"\>\<metaname=\"viewport\"content=\"width=device-width\,initial-scale=1.0\"\>\<title\>SmartDiff\</title\>\<linkrel=\"stylesheet\"href=\"https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.9.0/styles/github.min.css\"/\>\<\!--diff2html-css--\>\<\!--diff2html-js-ui--\>\<script\>document.addEventListener\(\'DOMContentLoaded\'\,\(\)=\>\{consttargetElement=document.getElementById\(\'diff\'\)\;constdiff2htmlUi=newDiff2HtmlUI\(targetElement\)\;//diff2html-fileListToggle//diff2html-synchronisedScroll//diff2html-highlightCode\}\)\;\</script\>\<style\>header\{display:flex\;justify-content:center\;\}header.filter\{margin-left:10px\;font-weight:bold\;\}\</style\>\</head\>\<body\>\<headerid=\"title\"\>\<label\>Filteredby:\</label\>\<spanclass=\"filter\"\>\<\!--smartdiff-filter-by--\>\</span\>\</header\>\<divid=\"diff\"\>\<\!--diff2html-diff--\>\</div\>\</body\>\</html\>"
#########################################
###########  src/config.sh  ##############
#########################################
VERSION=0.2.6
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
#########################################
###########  src/deps.sh  ##############
#########################################
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

# Checks that package is installed by running
# $package --version command
# Returns 0 if installed and 1 if not.
function check_package() {
    version=$($1 --version 2>/dev/null || echo "null")
    [[ $version == "null" ]] && echo "1" || echo "0"
}

#########################################
###########  src/updates.sh  ##############
#########################################
# Checks the latest version and updates package to it
function check_update() {
    latest=$(curl -s https://api.github.com/repos/$REPO/releases/latest | jq .tag_name | gnu_sed -En "s/\"v(.*)\"/\1/p")
    if [ "$latest" != "$VERSION" ]
    then
        read -s -rp $'A new version is available. Would you like to update? (Y/n)\n' -n 1 confirmation
        if [[ "${confirmation:-Y}" =~ ^[Yy]$ ]]
        then
            echo "Trying to update the smartdiff...
If it didn't work please run the next command manualy:

curl -o- https://raw.githubusercontent.com/$REPO/v$latest/install.sh | bash
"
            curl -o- https://raw.githubusercontent.com/$REPO/v$latest/install.sh
            exit 0
        fi
    fi
}
#########################################
###########  src/utils.sh  ##############
#########################################
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

# diff2html -s side -f html -d word -i file -o preview --hwt ./ui.html -- /tmp/smartdiff.diff#########################################
###########  src/git_utils.sh  ##############
#########################################
# Returns current branch name
function current_branch() {
    echo $(git rev-parse --abbrev-ref HEAD)
}


function stash() {
    log "Stashing the working directory"
    STASH_RESULT=$(git stash)
    set_config 'stash_result' $STASH_RESULT
}

function unstash() {
    stash_list=$(git stash list)
    if [ "$stash_list" != '' ] && [ "$stash_result" != 'No local changes to save' ]
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


# 
function cherry_pick() {
    for ((i=1;i<=$#;i++))
    do
        set_config 'current_ref_index' $i
        log "Cherry-picking ${!i}..."
        git cherry-pick ${!i}
        if [ $? -eq 1 ]
        then
            print_conflict_message
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
        print_conflict_message
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
            print_conflict_message
            exit 1
        fi
    done
}


#########################################
###########  src/run.sh  ##############
#########################################
# -------- Checking all dependencies --------- #
dependencies_checks=$(check_deps ${DEPS[@]})

if [ "$dependencies_checks" != "" ]
then
    echo $dependencies_checks
    exit 1
fi

# -------- Checking for updates  ------------- #
check_update

# --------- Running the script ----------------#
case "$1" in
    --version)
        echo "Smart Diff "$VERSION
        exit 0
    ;;
    --filter)
        # TODO: is it git repo check
        createDirIfNotExist $HOMEPATH

        if [ -f $STATUS_FILE ]
        then
            parse_config
            clean_up
        fi


        createFileIfNotExist $STATUS_FILE
        original_branch=$(current_branch)
        diff_branch="smart-diff-$FILTER_BY"

        set_config 'FILTER_BY' $FILTER_BY
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
            # TODO: colorize messages
            echo $'There is nothing to continue..\n'
            bash $0 --help
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
