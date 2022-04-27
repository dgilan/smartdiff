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

