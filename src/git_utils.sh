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


