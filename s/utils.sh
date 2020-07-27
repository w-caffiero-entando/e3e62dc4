# UTILS

# CFG

save_cfg_value() {
  local V
  V=$(printf "\"%q\"" "$2")
  if [[ -f $CFG_FILE ]]; then
    sed --in-place='' "/^$1=.*$/d" $CFG_FILE
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

# INTERACTION

prompt() {
  ask "$1" notif
}

ask() {
  while true; do
    [ "$2" == "notif" ] && echo -ne "$1" || echo -ne "$1 (y/n/q)"
    if [ "$OPT_YES_FOR_ALL" = true ]; then
      echo " (auto-yes/ok)"
      return 0
    fi
    
    # shellcheck disable=SC2162
    read -p " " res
    [ "$2" == "notif" ] && return 0
    case $res in
        [Yy]* ) return 0;;
        [Nn]* ) return 1;;
        [Qq]* ) exit 99;;
        * ) echo "Please answer yes, no or quit.";;
    esac
  done
}

FATAL() {
  echo -e "---"
  _log_e 0 "$@"
  xu_set_status "FATAL: $*"
  exit 77
}

EXIT_UE() {
  echo -e "---"
  [ "$1" != "" ] && _log_w 0 "$@"
  xu_set_status "USER-ERROR"
  exit 1
}

# PROGRAM STATUS

xu_clear_status() {
  [ "$XU_STATUS_FILE" != "" ] && [ -f "$XU_STATUS_FILE" ] && rm -- "$XU_STATUS_FILE"
}

xu_set_status() {
  [ "$XU_STATUS_FILE" != "" ] && echo "$@" > "$XU_STATUS_FILE"
}

xu_get_status() {
  XU_RES=""
  if [ "$XU_STATUS_FILE" != "" ] && [ -f "$XU_STATUS_FILE" ]; then
     XU_RES="$(cut "$XU_STATUS_FILE" -d':' -f1)"
  fi
  return 0
}
