#!/bin/bash

VERSION=$1
DESCRIPTION=$2
if [ "$VERSION" == '' ]
then
    echo 'You must specify the release version'
    exit 1
fi

if [ "$DESCRIPTION" == '' ]
then
    echo 'You must specify the release description'
    exit 1
fi

if [ "$GITHUB_TOKEN" == '' ]
then
    echo 'Setup gitub token first.'
    exit 1
fi

if [ $(git tag -l "v$VERSION") ]; then
    echo 'This tag already exists.'
    exit 1
fi

sed -i "s/VERSION=[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+/VERSION=$VERSION/" ./install.sh
sed -i "s/VERSION=[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+/VERSION=$VERSION/" ./smartdiff.sh
sed -i "s/\/v[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+\//\/v$VERSION\//g" ./README.md

git add install.sh smartdiff.sh README.md
git commit -m "Releasing $VERSION"

git tag v$VERSION
git push origin main
git push origin v$VERSION

curl \
  -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/dgilan/smartdiff/releases \
  -d "{\"tag_name\":\"v$VERSION\",\"name\":\"v$VERSION\",\"body\":\"$DESCRIPTION\",\"draft\":false,\"prerelease\":false,\"generate_release_notes\":false}"
