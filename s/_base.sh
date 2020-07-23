
# REPO_CUSTOM_MODEL
REPO_CUSTOM_MODEL_ADDR="https://github.com/entando-k8s/entando-k8s-custom-model.git"
REPO_CUSTOM_MODEL_DIR="entando-k8s-custom-model"

# REPO_QUICKSTART
REPO_QUICKSTART_ADDR="https://github.com/entando-k8s/entando-helm-quickstart.git"
REPO_QUICKSTART_DIR="entando-helm-quickstart"

# MISC
DEPL_SPEC_YAML_FILE="entando-deployment-specs.yaml"
REQUIRED_HELM_VERSION_REGEX="3.2.*"

# KUBECTL
#KK="sudo kubectl"
KK="echo sudo kubectl"

CFG_FILE="w/.status"

# UTILS
save_cfg_value() {
  local V
  V=$(printf "\"%q\"" "$2")
  if [[ -f $CFG_FILE ]]; then
    sed -i "/^$1=.*$/d" $CFG_FILE
  fi 
  if [ -n "$2" ]; then
    echo "$1=$V" >> $CFG_FILE
  fi
  return 0
}

reload_cfg() {
  set -a
  # shellcheck disable=SC1091
  [[ -f $CFG_FILE ]] && . $CFG_FILE
  set +a
  return 0
}


[ -f d/_env ] && . d/_env
[ -f w/_env ] && . w/_env
