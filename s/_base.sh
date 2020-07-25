[ -z $ZSH_VERSION ] && [ -z $BASH_VERSION ] && echo "Unsupported shell, user either bash or zsh" 1>&2 && exit 99

[ "$ENTANDO_ENT_ACTIVE" = "" ] && echo "No instance is currently active" && exit 99

nvm_activate() {
  NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || return
  export NVM_DIR
}

# KUBECTL
#KK="sudo kubectl"
KK="echo sudo kubectl"

# TRAPS
function backtrace() {
    xu_get_status
    if [ "$XU_RES" != "FATAL" ] && [ "$XU_RES" != "USER-ERROR" ] && [ "$XU_RES" != "EXIT" ]; then
      n=${#FUNCNAME[@]}
      
      echo "" 2>&1
      echo "###########################################################" 2>&1
      echo "###########################################################" 2>&1
      echo "###########################################################" 2>&1
      echo -e "> Error detected\n" 2>&1
      
      for ((i=1; i<n; i++)); do
          printf '%*s' "$i" ' '
          echo "${FUNCNAME[$i]}(), ${BASH_LINENO[$((i-1))]}, line ${BASH_SOURCE[$((i-1))]}" 2>&1
      done
      
      xu_set_status "EXIT"
    fi
}

set -o errtrace
trap backtrace ERR

# UTILS
. s/utils.sh
. s/logger.sh

# ENVIROMENT
mkdir -p "$ENTANDO_ENT_ACTIVE/w"
mkdir -p "$ENTANDO_ENT_ACTIVE/d"
mkdir -p "$ENTANDO_ENT_ACTIVE/lib"

. s/_conf.sh

ENT_RUN_TMP_DIR=$(mktemp /tmp/ent.run.XXXXXXXXXXXX)

exit-trap() { 
  xu_get_status

  sz=$(stat --printf="%s" "$ENT_RUN_TMP_DIR")
  if [ "$sz" -eq 0 ] || ( [ "$XU_RES" != "FATAL" ] && [ "$XU_RES" != "USER-ERROR" ] ); then
    rm -rf "$ENT_RUN_TMP_DIR"
  else
    echo "---"
    echo "[EXIT-TRAP] Execution info are available under: \"$ENT_RUN_TMP_DIR\""
    echo ""
  fi
}
trap exit-trap EXIT

xu_clear_status
