#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/.."

. s/_base.sh

set -e

reload_cfg


# CHECKS
CURRENT_HELM_VERSION=$(helm version --client | sed 's/.*SemVer:"\([^"]*\)".*/\1/')
[[ ! "$CURRENT_HELM_VERSION" =~ $REQUIRED_HELM_VERSION_REGEX ]] && echo "> FATAL: Found helm version $CURRENT_HELM_VERSION, required: $REQUIRED_HELM_VERSION_REGEX" 1>&2 && exit

# CUSTOM MODEL
cp -i -r "w/hqs/$REPO_CUSTOM_MODEL_DIR/src/main/resources/crd/" "d"

# SPECIFICATION
cd "w/hqs/$REPO_QUICKSTART_DIR"
IP=$(hostname -I | awk '{print $1}')
sed "s/supportOpenshift:.*/supportOpenshift: false/" values.yaml.tpl > values.yaml
helm template "$ENTANDO_APP_NAME" --namespace="$ENTANDO_NAMESPACE" ./ > "$DEPL_SPEC_YAML_FILE"

cd "$DIR/.."
mv "w/hqs/$REPO_QUICKSTART_DIR/$DEPL_SPEC_YAML_FILE" "d/$DEPL_SPEC_YAML_FILE.tpl"
