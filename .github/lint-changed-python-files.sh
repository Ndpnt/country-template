#! /usr/bin/env bash

last_tagged_commit=`git describe --always --tags --abbrev=0 --first-parent`  # --first-parent ensures we don't follow tags not published in main through an unlikely intermediary merge commit

if [ $? -ne 0 ]
then
    echo "Error: Failed to find the last tagged commit."
    exit 1
fi

if ! changed_files=$(git diff-index --name-only --diff-filter=ACMR --exit-code $last_tagged_commit -- "*.py")
then
  echo "Linting the following Python files:"
  echo $changed_files
  flake8 $changed_files
else echo "No changed Python files to lint"
fi
