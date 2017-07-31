#!/bin/sh

set -e
if ! git rev-parse `python setup.py --version` 2>/dev/null ; then
    git tag `python setup.py --version`
    git push --tags  # update the repository version
    python setup.py bdist_wheel  # build this package in the dist directory
    twine upload dist/* --username $PYPI_USERNAME --password fakeyfakey # publish
else
    echo "No deployment - Existing release with `python setup.py --version` version number"
fi