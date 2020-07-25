#!/bin/bash

[ "$1" = "-h" ] && echo -e "Checks the required dependencies | Syntax: ${0##*/}" && exit 0

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/.."

. s/_base.sh


# MISC

check_ver "sed" "*.*.*" "--version | head -n 1 2>/dev/null" || FATAL "Quitting"
check_ver "awk" "*.*.*" "--version | head -n 1 2>/dev/null" || FATAL "Quitting"
check_ver "grep" "*.*.*" "--version | head -n 1 2>/dev/null" || FATAL "Quitting"
check_ver "cat" "*.*.*" "--version | head -n 1 2>/dev/null" || FATAL "Quitting"
check_ver "hostname" "*.*.*" "--version | head -n 1 2>/dev/null" || FATAL "Quitting"
check_ver "curl" "*.*.*" "--version | head -n 1 2>/dev/null" || FATAL "Quitting"
check_ver "watch" "*.*.*" "-v 2>/dev/null" || {
  prompt "Recomended dependency \"watch\" not found, some tool may not work as expected.\nPress enter to continue.."
}

# NVM
nvm_activate
check_ver "nvm" "$VER_NVM_REQ" "--version 2>&1" verbose || {
  ask "Should I try to install it?" && {
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$VER_NVM_DEF/install.sh | bash
  } || {
    FATAL "Mandatory dependency not available"
  }
}
nvm_activate

# NODE
check_ver "node" "$VER_NODE_REQ" "--version 2>&1" verbose || {
  ask "Should I try to install it?" && {
    nvm install $VER_NODE_DEF
  } || {
    FATAL "Mandatory dependency not available"
  }
}

# JHIPSTER
check_ver "jhipster" "$VER_JHIPSTER_REQ" "-V 2>&1 | grep -v INFO" verbose || {
  ask "Should I try to install it?" && {
    npm install generator-jhipster@$VER_JHIPSTER_DEF
  } || {
    FATAL "Mandatory dependency not available"
  }
}

# ENTANDO-GENERATOR-JHIPSTER (entando blueprint)
_log_i 3 "Checking ENT installation of generator-jhipster-entando.."

cd $ENTANDO_ENT_ACTIVE
[ -d "lib/generator-jhipster-entando/$VER_GENERATOR_JHIPSTER_ENTANDO_REQ/" ] && {
  _log_i 3 "\tfound: $VER_GENERATOR_JHIPSTER_ENTANDO_REQ => OK"
} || {
  _log_i 2 "Version \"$VER_GENERATOR_JHIPSTER_ENTANDO_REQ\" of \"generator-jhipster-entando\" was not found"
  
  ask "Should I try to install it?" && {
    mkdir -p "lib/generator-jhipster-entando/"
    cd "lib/generator-jhipster-entando/"
    git clone "$C_ENTANDO_BLUEPRINT_REPO" "$VER_GENERATOR_JHIPSTER_ENTANDO_DEF"
    cd "$VER_GENERATOR_JHIPSTER_ENTANDO_DEF"
    git checkout -b $VER_GENERATOR_JHIPSTER_ENTANDO_DEF $VER_GENERATOR_JHIPSTER_ENTANDO_DEF
    npm link
  } || {
    FATAL "Mandatory dependency not available"
  }  
}
cd - > /dev/null
