#!/bin/bash

H() { echo -e "Helps managing repositories | Syntax: (run ${0##*/} -h full-help)"; }
[ "$1" = "-h" ] && H && exit 0

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/.." || { echo "Internal error: unable to find the script source dir"; exit; }
. s/_base.sh
cd - >/dev/null

P_REPO_USER="";
P_REPO_PASS=""

RUN() {
  cmd=$1;
  shift

  [ -z $cmd ] && H && exit 99

  while true; do
    case "$cmd" in 
      "-i") REPO_MODE="image";;
      "-b") REPO_MODE="bundle";;
      "init")
        set_nn_dn "ADDR_OF_ORIGIN" "${1-}"; shift
        
        _set_var "USER_NAME" "${1-}"; shift
        _set_var "USER_EMAIL" "${1-}"; shift
        
        ensure_valid_location initialized
        
        $NESTED_IN_PROJECT_BUNDLE && assume_project_info
        
        [ -z "$USER_NAME" ] && FATAL "Please provide a valid user name either in the project dir or in the package dir"
        [ -z "$USER_EMAIL" ] && FATAL "Please provide a valid user email either in the project dir or in the package dir"
  
        repo_init;;    
      "bump")
        set_nn_fdn "VERSION_NUMBER" "${1-}"; shift
        repo_bump;;    
      "creds")
        if [ "$REPO_MODE" == "bundle" ]; then
          EXIT_UE "inline credentials are not supported for npm BUNDLE repos"
        fi
        set_nn_dn "P_REPO_USER" "${1-}"; shift
        
        tmp="${1-}"
        [ -z "$tmp" ] && echo "Password?" && read -s tmp

        _set_nn "P_REPO_PASS" "${tmp-}"; shift
        ;;
      "login")
        ADDR=${1-}; shift;
        assert_lit "as" "${1-}"; shift
        set_nn_dn-id "REPO_ALIAS" "${1-}"; shift
        set_nn_dn "P_${REPO_ALIAS}_REPO_ADDRESS" "$ADDR"
        repo_login;;
      "logout")
        assert_lit "from" "${1-}"; shift
        set_nn_dn-id "REPO_ALIAS" "${1-}"; shift
        repo_logout;;
      *)
        H
      ;;
    esac
    shift
    [ -z $1 ] && break
  done
}

repo_login() {
  CHECK_ENV bundle
  reload_cfg
  
  local ADDR_VAR="${REPO_MODE}_${REPO_ALIAS}_REPO_ADDRESS"
  local ADDR_PAR="P_${ADDR_VAR}"
  
  case "${REPO_MODE}" in
    "BUNDLE")
      # BUNDLE REPO LOGIN
      (
        ADDR="${!ADDR_PAR}"
        if [ "$ADDR" != "" ]; then
          _log_i 1 "Logging in to the BUNDLE REPO ($ADDR)"
          npm login --registry="$ADDR" || return $?
          save_nn_cfg_value "$ADDR_VAR" "$ADDR"
        else
          FATAL "Null BUNDLE repo address"
        fi
        
        _log_i 1 "Done."
      ) || return $?
      ;;
    "PLUGIN")
      # PLUGIN REPO LOGIN
      (
        local ADDR="${!ADDR_PAR}"
        if [ "$ADDR" != "" ]; then
          _log_i 1 "Logging in to the PLUGIN REPO ($ADDR)"
          
          [ -n "$P_PLUGIN_REPO_USER" ] && P_PLUGIN_REPO_USER_O="-u $P_PLUGIN_REPO_USER"
          
          if [ -n "$P_PLUGIN_REPO_PASS" ]; then
            echo "$P_PLUGIN_REPO_PASS" | docker login "$P_PLUGIN_REPO_USER_O" --password-stdin -- "$ADDR"
          else
            BASE="$(echo "$ADDR" | cut -d"/" -f3)"
            docker login "$P_PLUGIN_REPO_USER_O" -- "$BASE" || return $?
          fi
          
          save_nn_cfg_value "$ADDR_VAR" "$ADDR"
        else
          FATAL "Null PLUGIN repo address"
        fi
        
        _log_i 1 "Done."
      ) || return $?
      ;;
    *)
      FATAL "Unknow REPO_MODE $REPO_MODE";;
  esac
}

# ------------------------------------------------------------

repo_logout() {
  CHECK_ENV bundle
  reload_cfg

  local B_ADDR_VAR="BUNDLE_${REPO_ALIAS}_REPO_ADDRESS"
  local P_ADDR_VAR="PLUGIN_${REPO_ALIAS}_REPO_ADDRESS"
  
  # BUNDLE REPO LOGOUT
  ADDR="${!B_ADDR_VAR}"
  if [ "$ADDR" != "" ]; then
    n=$((n+1))
    _log_i 1 "Logging out from BUNDLE REPO ($ADDR)"
    save_cfg_value "$ADDR_VAR" ""
    npm logout --registry="$ADDR" || (
      _log_w 1 "Failed." || true
    ) && (
      _log_i 1 "Done."
    )
  fi
  return 0

  # PLUGIN REPO LOGOUT
  ADDR="${!P_ADDR_VAR}"
  if [ "$ADDR" != "" ]; then
    n=$((n+1))
    _log_i 1 "Logging out from the PLUGIN REPO ($ADDR)"
    save_cfg_value "$ADDR_VAR" ""
    docker logout "$ADDR" || (
      _log_w 1 "Failed." || true
    ) && (
      _log_i 1 "Done."
    )
  fi
  return 0
  
  [ $n -eq 0 ] && _log_w 1 "No active session was found for the given alias (${REPO_ALIAS})"
}

repo_init() {
  ensure_valid_location
  [ ! -f .git ] && { git init; }
  O=$(git remote get-url origin 2>/dev/null)
  [ ! -z "$O" ] && { 
    ask "An origin is already present ($O) do you want ot overwrite it?" || EXIT_UE "User abort" 
    git remote remove origin
  }
  
  T=$(cat ../.gitignore | grep "^bundle/$")
  [ "$T" == "" ] && {
    echo -e "\n####\nbundle/" >> ../.gitignore 
    _log_d 1 "bundle project .gitignore updated"
  }

  git remote add origin "$ADDR_OF_ORIGIN"
  assert_nn "USER_NAME" "$USER_NAME"
  assert_nn "USER_EMAIL" "$USER_EMAIL"
  git config user.name "$USER_NAME"
  git config user.email "$USER_EMAIL"
  _log_i 1 "bundle package repository initialized"
}

repo_bump() {
  ensure_valid_location initialized
  git add -A
  git commit -m "== Bump $VERSION_NUMBER"
  T=$(git tag | grep "$VERSION_NUMBER" | wc -l)
  [ $T -eq 0 ] && {
    git tag "$VERSION_NUMBER"
  } || {
    ask "Version \"$VERSION_NUMBER\" already exists, do you want to overwrite it?" {
    git tag "$VERSION_NUMBER"
  }
}


ensure_valid_location() {
  F=false;NESTED_IN_PROJECT_BUNDLE=false;
  [ -f "$C_BUNDLE_DESCRIPTOR_FILE_NAME" ] && F=true
  [ -f "bundle/$C_BUNDLE_DESCRIPTOR_FILE_NAME" ] && NESTED_IN_PROJECT_BUNDLE=true && cd bundle && F=true
  
  $F || FATAL "This doesn't seem to be a bundle project or a bundle repo dir"
  
  if [ "$1" = "initialized" ]; then
    O=$(git remote get-url origin 2>/dev/null)
    [ -z "$O" ] && FATAL "Repo not initialized (run \"${0##*/} init ...\")"
  fi

  return 0
}

assume_project_info() {
  cd ..
  [ -z "$USER_NAME" ] && {
    USER_NAME=$(git config user.name 2>/dev/null)
    [ ! -z "$USER_NAME" ] && _log_d 1 "Assuming user name \"$USER_NAME\" from the bundle project dir"
  }
  [ -z "$USER_EMAIL" ] && {
    USER_EMAIL=$(git config user.email 2>/dev/null)
    [ ! -z "$USER_EMAIL" ] && _log_d 1 "Assuming user email \"$USER_EMAIL\" from the bundle parent project dir"
  }
  cd - >/dev/null
}

syntax() {
  echo "> ${0##*/} repo login {REPO_ADDRESS}"
  echo "> ${0##*/} repo logout"
}

RUN "$@"
