#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/.."

. s/_base.sh

set -e

NS="$1"
[ "$NS" == "" ] && NS="$ENTANDO_NAMESPACE"
[ "$NS" == "" ] && echo "please provide the namespace name" 1>&2 && exit 1
shift

AN="$1"
[ "$AN" == "" ] && AN="$ENTANDO_APPNAME"
[ "$AN" == "" ] && echo "please provide the app name" 1>&2 && exit 1

save_cfg_value "ENTANDO_NAMESPACE" "$NS"
save_cfg_value "ENTANDO_APP_NAME" "$AN"

# PREREQ
mkdir -p w
mkdir w/hqs

CURRENT_HELM_VERSION=$(helm version --client | sed 's/.*SemVer:"\([^"]*\)".*/\1/')
[[ ! "$CURRENT_HELM_VERSION" =~ $REQUIRED_HELM_VERSION_REGEX ]] && echo "> FATAL: Found helm version $CURRENT_HELM_VERSION, required: $REQUIRED_HELM_VERSION_REGEX" 1>&2 && exit

echo "> Found helm version $CURRENT_HELM_VERSION => OK"


# -- REPOS
cd w/hqs

# REPOS -- CUSTOM MODEL

git clone "$REPO_CUSTOM_MODEL_ADDR" "$REPO_CUSTOM_MODEL_DIR"
cd "$REPO_CUSTOM_MODEL_DIR"
git checkout -b "$REPO_CUSTOM_MODEL_TAG"
cd ..

# REPOS -- QUICKSTART

git clone "$REPO_QUICKSTART_ADDR" "$REPO_QUICKSTART_DIR"
cd "$REPO_QUICKSTART_DIR"
git checkout -b "$REPO_QUICKSTART_TAG"
[ ! -f values.yaml.tpl ] && cp values.yaml values.yaml.tpl
cd ..

# --
cd ..

