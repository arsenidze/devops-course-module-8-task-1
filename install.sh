#!/usr/bin/env bash

set -e;

# Define the hook name and the content of the hook script
HOOK_NAME="pre-commit"
HOOK_CONTENT=$(cat <<'EOF'
#!/bin/bash

set -e;

checkgitleaks=$(git config --bool hooks.checkgitleaks)

# Redirect output to stderr.
exec 1>&2

PATH_TO_SCRIPT=$(dirname "$0")
GITLEAKS_SOURCE=

install_git_leaks () {
	if [ -x "${PATH_TO_SCRIPT}/gitleaks_for_git_precommit_hook" ]; then
		# use localy installed gitleaks with binary name - gitleaks_for_git_precommit_hook
		GITLEAKS_SOURCE="${PATH_TO_SCRIPT}/gitleaks_for_git_precommit_hook"
	elif ! [ -x "$(command -v gitleaks1)" ]; then
		if ! [ -x "$(command -v go)" ]; then
			echo 'Error: go is not installed.' >&2
			exit 1
		fi
		if ! [ -x "$(command -v make)" ]; then
			echo 'Error: make is not installed.' >&2
			exit 1
		fi

		# install local version of gitleaks with binary name - gitleaks_for_git_precommit_hook
		pushd $PATH_TO_SCRIPT
		GITLEAKS_REPO_NAME="gitleaks_random_30cdc892-5280-40a9-8cd1-83a92396ffe4"
		git clone https://github.com/gitleaks/gitleaks.git $GITLEAKS_REPO_NAME
		pushd $GITLEAKS_REPO_NAME
		make build
		mv gitleaks gitleaks_for_git_precommit_hook
		mv gitleaks_for_git_precommit_hook ../
		popd
		rm -rf $GITLEAKS_REPO_NAME
		GITLEAKS_SOURCE="${PATH_TO_SCRIPT}/gitleaks_for_git_precommit_hook"
		popd
	else
		# use globally installed version of gitleaks
		GITLEAKS_SOURCE=$(command -v gitleaks)
	fi
}

if [ "$checkgitleaks" = "true" ]; then
	install_git_leaks

	$GITLEAKS_SOURCE protect --source . --staged -v
	$GITLEAKS_SOURCE detect --source . -v
fi
EOF
)

# Define the path to the hook file
HOOK_FILE=".git/hooks/$HOOK_NAME"

# Create the hooks directory if it doesn't exist
mkdir -p "$(dirname "$HOOK_FILE")"

# Write the hook content to the file
echo "$HOOK_CONTENT" > "$HOOK_FILE"

# Make the hook script executable
chmod +x "$HOOK_FILE"

# Optionally modify Git config (e.g., set a custom config value)
git config --local hooks.checkgitleaks "true"

# Confirm installation
echo "$HOOK_NAME hook has been installed and Git config updated."
