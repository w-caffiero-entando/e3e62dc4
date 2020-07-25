#!/bin/bash

ENTANDO_NAMESPACE="$1"
[ "$ENTANDO_NAMESPACE" == "" ] && echo "please provide the namespace name" 1>&2 && exit 1
shift

ENTANDO_APPNAME="$1"
[ "$ENTANDO_APPNAME" == "" ] && echo "please provide the app name" 1>&2 && exit 1
shift

RUN() {
  INGR=$(sudo k3s kubectl get ingress -n "$ENTANDO_NAMESPACE")

  ingr_check "Keycloak" "kc-ingress" "auth/"
  ingr_check "ECI" "eci-ingress" "k8s/"
  ingr_check "APP" "$ENTANDO_APPNAME-ingress" "app-builder/"

  echo -e "\n~~~\n"
  
  sudo k3s kubectl get pods -n "$ENTANDO_NAMESPACE";
}

ingr_check() {
  ADDR=$(echo "$INGR" | grep "$2" | awk '{print $3}')

  if [ ! -z "$ADDR" ]; then
    echo -n "> $1 entrypoint open.."
    http_check "$ADDR/$3"
    
    T="\t(http://$ADDR/$3)"

    case "$?" in
      0) echo -e " AND READY $T" && return 0;;
      1) echo -e " but not ready yet ($http_check_res) $T" && return 1;;
      2) echo -e " AND IN ERROR ($http_check_res) $T" && return 1;;
      *) echo -e " AND IN UNEXPECTED STATUS ($http_check_res) $T" && return 1;;
    esac
  else
    echo "$1 entrypoint closed.."
  fi
}

http_check() {
  http_check_res=$(curl --write-out '%{http_code}' --silent --output /dev/null "$1")

  case "$http_check_res" in
    2*) return 0;;
    401) return 0;;
    4*) return 1;;
    5*) return 2;;
    *) return 3;;
  esac

  return 1  
}

RUN
