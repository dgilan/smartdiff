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
