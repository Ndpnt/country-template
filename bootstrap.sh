#!/bin/bash

set -e
GREEN='\033[0;32m'
PURPLE='\033[1;35m'
YELLOW='\033[0;33m'
BLUE='\033[1;34m'
JURISDICTION_NAME=${JURISDICTION_NAME:-$COUNTRY_NAME}  # backwards compatibility

if [[ $JURISDICTION_NAME ]] && [[ $REPOSITORY_URL ]]
then continue=Y
fi

if [[ -d .git ]]
then
	echo 'It seems you cloned this repository, or already initialised it.'
	echo 'Refusing to go further as you might lose work.'
	echo "If you are certain this is a new repository, run 'cd $(dirname $0) && rm -rf .git' to erase the history."
	exit 2
fi

while [[ ! "$JURISDICTION_NAME" ]]
do
	echo -e "${GREEN}The name of the jurisdiction (usually a country, e.g. New Zealand, France…) you will model the rules of: \033[0m"
	read JURISDICTION_NAME
done

lowercase_jurisdiction_name=$(echo $JURISDICTION_NAME | tr '[:upper:]' '[:lower:]' | sed 'y/āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜĀÁǍÀĒÉĚÈĪÍǏÌŌÓǑÒŪÚǓÙǕǗǙǛ/aaaaeeeeiiiioooouuuuüüüüAAAAEEEEIIIIOOOOUUUUÜÜÜÜ/')
NO_SPACES_JURISDICTION_LABEL=$(echo $lowercase_jurisdiction_name | sed -r 's/[ ]+/_/g') # allow for hyphens to be used in jurisdiction names
SNAKE_CASE_JURISDICTION=$(echo $NO_SPACES_JURISDICTION_LABEL | sed -r 's/[-]+/_/g') # remove hyphens for use in Python

while [[ ! "$REPOSITORY_URL" ]]
do
	echo -e "${GREEN}Your Git repository URL: \033[0m (i.e. https://githost.example/organisation/openfisca-jurisdiction)"
	read REPOSITORY_URL
done

REPOSITORY_FOLDER=$(echo ${REPOSITORY_URL##*/})

cd $(dirname $0)  # support being called from anywhere on the file system

echo -e "${PURPLE}Jurisdiction title set to: \033[0m${BLUE}$JURISDICTION_NAME\033[0m"
# Removes hyphens for python environment
echo -e "${PURPLE}Jurisdiction Python label: \033[0m${BLUE}$SNAKE_CASE_JURISDICTION\033[0m"
echo -e "${PURPLE}Git repository URL       : \033[0m${BLUE}$REPOSITORY_URL\033[0m"

while [[ $continue != "y" ]] && [[ $continue != "Y" ]]
do
	read -p "Would you like to continue (type Y for yes, N for no): " continue
	if [[ $continue == "n" ]] || [[ $continue == "N" ]]
	then exit 3
	fi
done

parent_folder=${PWD##*/}
package_name="openfisca_$SNAKE_CASE_JURISDICTION"

last_bootstrapping_line_number=$(grep --line-number '^## Writing the Legislation' README.md | cut -d ':' -f 1)
last_changelog_number=$(grep --line-number '^# Example Entry' CHANGELOG.md | cut -d ':' -f 1)

first_commit_message='Initial import from OpenFisca country-template'
second_commit_message='Customise country-template through script'

echo
cd ..
mv $parent_folder openfisca-$NO_SPACES_JURISDICTION_LABEL
cd openfisca-$NO_SPACES_JURISDICTION_LABEL

echo -e "${PURPLE}*  ${PURPLE}Initialise git repository\033[0m"
git init --initial-branch=main > /dev/null 2>&1
git add .

git commit --no-gpg-sign --message "$first_commit_message" --author='OpenFisca Bot <bot@openfisca.org>' --quiet
echo -e "${PURPLE}*  ${PURPLE}Initial git commit made to 'main' branch: '\033[0m${BLUE}$first_commit_message\033[0m${PURPLE}'\033[0m"

all_module_files=`find openfisca_country_template -type f ! -name "*.DS_Store"`
echo -e "${PURPLE}*  ${PURPLE}Replace default country_template references\033[0m"
# Use intermediate backup files (`-i`) with a weird syntax due to lack of portable 'no backup' option. See https://stackoverflow.com/q/5694228/594053.
sed -i.template "s|openfisca-country_template|openfisca-$NO_SPACES_JURISDICTION_LABEL|g" README.md Makefile pyproject.toml CONTRIBUTING.md
sed -i.template "s|country_template|$SNAKE_CASE_JURISDICTION|g" README.md pyproject.toml .flake8 .github/workflows/workflow.yml Makefile MANIFEST.in $all_module_files
sed -i.template "s|Country-Template|$JURISDICTION_NAME|g" README.md pyproject.toml .github/workflows/workflow.yml .github/PULL_REQUEST_TEMPLATE.md CONTRIBUTING.md

echo -e "${PURPLE}*  ${PURPLE}Remove bootstrap instructions\033[0m"
sed -i.template -e "3,${last_bootstrapping_line_number}d" README.md  # remove instructions lines

echo -e "${PURPLE}*  ${PURPLE}Prepare \033[0m${BLUE}README.MD\033[0m${PURPLE} and \033[0m${BLUE}CONTRIBUTING.md\033[0m"
sed -i.template "s|https://example.com/repository|$REPOSITORY_URL|g" README.md CONTRIBUTING.md

echo -e "${PURPLE}*  ${PURPLE}Prepare \033[0m${BLUE}CHANGELOG.md\033[0m"
sed -i.template -e "1,${last_changelog_number}d" CHANGELOG.md  # remove country-template CHANGELOG leaving example

echo -e "${PURPLE}*  ${PURPLE}Prepare \033[0m${BLUE}pyproject.toml\033[0m"
sed -i.template "s|https://github.com/openfisca/country-template|$REPOSITORY_URL|g" pyproject.toml
sed -i.template "s|:: 5 - Production/Stable|:: 1 - Planning|g" pyproject.toml
sed -i.template "s|repository_folder|$REPOSITORY_FOLDER|g" README.md
find . -name "*.template" -type f -delete

echo -e "${PURPLE}*  ${PURPLE}Rename package to: \033[0m${BLUE}$package_name\033[0m"
git mv openfisca_country_template $package_name

echo -e "${PURPLE}*  ${PURPLE}Remove single use \033[0m${BLUE}bootstrap.sh\033[0m${PURPLE} script\033[0m"
git rm bootstrap.sh > /dev/null 2>&1
git add .
git commit --no-gpg-sign --message "$second_commit_message" --author='OpenFisca Bot <bot@openfisca.org>' --quiet

echo -e "${PURPLE}*  ${PURPLE}Second git commit made to 'main' branch: '\033[0m${BLUE}$second_commit_message\033[0m${PURPLE}'\033[0m"
echo

git remote add origin $REPOSITORY_URL.git

cd ../openfisca-$NO_SPACES_JURISDICTION_LABEL

echo -e "${YELLOW}* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * \033[0m"
echo -e "${YELLOW}*\033[0m"
echo -e "${YELLOW}*\033[0m  Bootstrap complete, you can now push to remote repository with '${BLUE}git push origin main\033[0m'"
echo -e "${YELLOW}*\033[0m  Then refer to the \033[0m${BLUE}README.md\033[0m"
echo -e "${YELLOW}*\033[0m  The parent directory name has been changed, you can use ${BLUE}cd ..\033[0m to navigate again to it"
echo -e "${YELLOW}*\033[0m"
echo -e "${YELLOW}* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * \033[0m"
