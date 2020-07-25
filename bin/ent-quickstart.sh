#!/bin/bash

[ "$1" = "-h" ] && echo -e "Automatically execute the quickstart deployment | Syntax: ${0##*/} [--destroy] [--static-ip] namespace appname" && exit 0

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/.."

. s/_base.sh

if [ "$1" == "--custom-ip" ]; then
  if [ "$ENTANDO_CUSTOM_IP" == "" ]; then
    ADDR="$ENTANDO_CUSTOM_IP"
    AUTO_ADD_IP=false
  else
    ADDR="$C_DEF_CUSTOM_IP"
    AUTO_ADD_IP=true
  fi
else
  ADDR="$(hostname -I | awk '{print $1}')"
  AUTO_ADD_IP=false
fi

if [ "$1" == "--destroy" ]; then
  reload_cfg
  sudo -v
  ask "Shoud I destroy the current deployed app ($ENTANDO_APPNAME)?" && {
    $KUBECTL delete namespace "$ENTANDO_NAMESPACE"
  }
  exit
fi

JUST_SET_CFG=false
if [ "$1" == "--config" ]; then
  JUST_SET_CFG=true
  shift
fi

ENTANDO_NAMESPACE="$1"
[ "$ENTANDO_NAMESPACE" == "" ] && echo "please provide the namespace name" 1>&2 && exit 1
shift

ENTANDO_APPNAME="$1"
[ "$ENTANDO_APPNAME" == "" ] && echo "please provide the app name" 1>&2 && exit 1
shift

save_cfg_value "ENTANDO_NAMESPACE" "$ENTANDO_NAMESPACE"
save_cfg_value "ENTANDO_APPNAME" "$ENTANDO_APPNAME"

$JUST_SET_CFG && echo "Config has been written" && exit 0

sudo -v

check_ver "k3s" "$VER_K3S_REQ" "--version 2>&1 | sed 's/k3s version \(.*\)+k.*/\1/'" && {
  _log_i 3 "\tfound: $check_ver_res => OK"
} || {
  ask "Should I try to install it?" && {
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$VER_K3S_DEF" sh -
  } || {
    FATAL "Mandatory dependency not available"
  }
}

_log_i 2 "Generating the kubernetes specification file for the deployment"

AUTO_ADD_IP && {
  netplan_add_custom_ip "$ADDR"
  sleep 1
}

net_is_address_present "$ADDR" || FATAL "The designated ip address is not present on the system"

cat "d/$DEPL_SPEC_YAML_FILE.tpl" \
  | sed "s/PLACEHOLDER_ENTANDO_NAMESPACE/$ENTANDO_NAMESPACE/" \
  | sed "s/PLACEHOLDER_ENTANDO_APPNAME/$ENTANDO_APPNAME/" \
  | sed "s/your\\.domain\\.suffix\\.com/$ADDR.nip.io/" \
  > "w/$DEPL_SPEC_YAML_FILE"

_log_i 3 "File \"w/$DEPL_SPEC_YAML_FILE\" generated"

ask "Should I register the CRDs?" && {
  $KUBECTL apply -f "d/crd"
}

ask "Should I start the deployment?" && {
  $KUBECTL create namespace "$ENTANDO_NAMESPACE"
  $KUBECTL create -f "w/$DEPL_SPEC_YAML_FILE"
}

ask "Should I start the monitor?" && {
  watch $KUBECTL get pods -n "$ENTANDO_NAMESPACE"
}
