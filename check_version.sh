#!/bin/bash

curl -s https://api.github.com/repos/dgilan/smartdiff/releases/latest | jq .tag_name

# wget https://api.github.com/repos/dgilan/smartdiff/releases/latest -O -
# echo $GITHUB_TOKEN

# curl \
#   -X POST \
#   -H "Authorization: token $GITHUB_TOKEN" \
#   -H "Accept: application/vnd.github.v3+json" \
#   https://api.github.com/repos/dgilan/smartdiff/releases \
#   -d '{"tag_name":"v0.0.1","name":"v0.0.1","body":"Description of the release","draft":false,"prerelease":false,"generate_release_notes":false}'


# curl -v -i -X POST -H "Content-Type:application/json" \
#  -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/dgilan/smartdiff/releases \ 
#  -d '{"tag_name":"v0.0.1","target_commitish": "develop","name": "0.0.1","body": "Release 0.0.2","draft": false,"prerelease": false}'