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

# Checks the SemVer of a program
# > check_ver <program> <expected-semver-pattern> <program-params-for-showing-version> <mode>
check_ver() {
  local mode="$4"
  _log_i 3 "Checking $1.."

  VER=$(eval "$1 $3")

  if [ -z "$VER" ]; then
    _log_i 2 "Program \"$1\" is not available"
    return 1
  fi
  
  P="${VER:0:1}"
  [ "${P^^}" == "V" ] && VER=${VER:1}
  
  IFS='.' read -r -a V <<< "$VER"
  f_maj="${V[0]}" && f_min="${V[1]}" && f_ptc="${V[2]}"
  IFS='.' read -r -a V <<< "$2"
  r_maj="${V[0]}" && r_min="${V[1]}" && r_ptc="${V[2]}"

    (
      [[ "$f_maj" != "$r_maj" ]] && [[ "$r_maj" != "*" ]] && return 1
      [[ "$f_min" != "$r_min" ]] && [[ "$r_min" != "*" ]] && return 1
      [[ "$f_ptc" != "$r_ptc" ]] && [[ "$r_ptc" != "*" ]] && return 1
      return 0
    ) && {
      check_ver_res="$VER"
      [ "$mode" == "verbose" ] && _log_i 3 "\tfound: $check_ver_res => OK"
      return 0
    } || {
      _log_i 2 "Version \"$2\" of program \"$1\" is not available (found: $VER)"
      return 1
    }
}

xu_clear_status() {
  [ "$XU_STATUS_FILE" != "" ] && rm -- "$XU_STATUS_FILE"
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

netplan_add_custom_ip() {
  F=$(ls /etc/netplan/* | head -n 1)
  [ ! -f "$F" ] && FATAL "This function only supports netplan based network configurations"
  grep -v addresses "$F" | sed '/dhcp4/a _addresses: [ '$1']' | sed 's/_/            /'
  sudo netplan generate
  sudo netplan apply
}

net_is_address_present() {
  [ (ip a s | grep "$ADDR" | wc -l) -gt 0 ] && return 0 || return 1
}
