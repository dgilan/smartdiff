# Checks the latest version and updates package to it
function check_update() {
    latest=$(curl -s https://api.github.com/repos/$REPO/releases/latest | jq .tag_name | sed -En "s/\"v(.*)\"/\1/p")
    if [ "$latest" != "$VERSION" ]
    then
        read -s -rp $'A new version is available. Would you like to update? (Y/n)\n' -n 1 confirmation
        if [[ "${confirmation:-Y}" =~ ^[Yy]$ ]]
        then
            curl -o- https://raw.githubusercontent.com/$REPO/v$latest/install.sh | bash
            exit 0
        else
            exit 1
        fi
    fi
}
