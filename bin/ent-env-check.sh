#!/bin/bash

H() { 
  [ "$1" == "brief" ] && {
    echo -e "Checks the required dependencies | Syntax: ${0##*/}"
  } || {
    echo -e "Checks the required dependencies\nSyntax: ${0##*/} develop|kube|kubeqs|full [lenient]"
    echo -e "  - develop: dependencies for bundle developers"
    echo -e "  - kube:    dependencies for a kubernetes execution environment"
    echo -e "  - kubeqs:  dependencies for a kubernetes execution environment based on the quickstart vm"
    echo -e "  - full:    all dependencies"
    echo -e "  - lenient: don't fail if a dependency is missing"
  }
}

[ "$1" = "-h" ] && {
  [ "$2" == "full-help" ] && { H "full-help" && exit 0; } || { H "brief" && exit 0; }
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR/.."

. s/_base.sh

M_DEVL=false;M_KUBE=false;M_QS=false;
case $1 in
  develop) M_DEVL=true;;
  kube) M_KUBE=true;;
  kubeqs) 
    ask "This mode will alter your resolv.conf. Do you want to proceed?" || FATAL "Quitting"
    M_KUBE=true;M_QS=true;;
  full) M_DEVL=true;M_KUBE=true;;
  *) H&&exit 0;;
esac
shift

[ "$1" == "lenient" ] && {
  MAYBE_FATAL() {
    FATAL "$@"
  }
  shift
} || {
  MAYBE_FATAL() {
    prompt "Recommended dependency not found, some tool may not work as expected.\nPress enter to continue.."
  }
}

# MISC

check_ver "git" "*.*.*" "--version | head -n 1" || MAYBE_FATAL "Quitting"
check_ver "sed" "*.*.*" "--version | head -n 1" || MAYBE_FATAL "Quitting"
check_ver "awk" "*.*.*" "--version | head -n 1" || MAYBE_FATAL "Quitting"
check_ver "grep" "*.*.*" "--version | head -n 1" || MAYBE_FATAL "Quitting"
check_ver "cat" "*.*.*" "--version | head -n 1" || MAYBE_FATAL "Quitting"
$M_KUBE && { check_ver "hostname" "*.*.*" "--version | head -n 1" || MAYBE_FATAL "Quitting"; }
$M_KUBE && { check_ver "dig" "*.*.*" "-v 2>&1" literal || MAYBE_FATAL "Quitting"; }
check_ver "curl" "*.*.*" "--version | head -n 1" || MAYBE_FATAL "Quitting"
$M_DEVL && { check_ver "watch" "*.*.*" "-v" || {
    prompt "Recommended dependency not found, some tool may not work as expected.\nPress enter to continue.."
  }
}

# DNS
$M_QS && {
  make_safe_resolv_conf
}

$M_KUBE && {
  _log_i 1 "Checking DNS"

  dns_state=$(s/check-dns-state.sh)

  case ${dns_state:-""} in
    "full")
      true;;
    "no-dns")
      _log_e 1 "SEVERE: This system appears to have no DNS."
      ask "Do you what to process anyway?" || FATAL "Quitting";;
    "filtered[RR]")
      _log_e 1 "SEVERE: DNS query for local adresses appears to be actively filtered."
      ask "Do you what to process anyway?" || FATAL "Quitting";;
    "filtered[R]")
      $M_QS && {
        _log_e 1 "SEVERE: Your DNS server appears to implement DNS rebinding protection, preventing queries like 192.168.1.1.nip.io to work."
        ask "Workaround didn't seem to work. Do you want to proceed anyway?" || FATAL "Quitting"
      } || {
        _log_e 1 "SEVERE: Your DNS server appears to implement DNS rebinding protection, preventing queries like 192.168.1.1.nip.io to work."
        ask "Should alter the resolv.conf?" && {
          make_safe_resolv_conf
        }
      }
      ;;
    "*") 
      _log_e 1 "SEVERE: Unable to precisely determine the status of the DNS."
      ask " Do you what to process anyway?" || FATAL "Quitting";;
  esac
}

# NVM
$M_DEVL && { 
  nvm_activate
  check_ver "nvm" "$VER_NVM_REQ" "--version" verbose || {
    ask "Should I try to install it?" && {
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$VER_NVM_DEF/install.sh | bash
    } || {
      MAYBE_FATAL "Mandatory dependency not available"
    }
  }
  nvm_activate
}

# NODE
$M_DEVL && { 
  check_ver "node" "$VER_NODE_REQ" "--version" verbose || {
    ask "Should I try to install it?" && {
      nvm install $VER_NODE_DEF
    } || {
      MAYBE_FATAL "Mandatory dependency not available"
    }
  }
}

# JHIPSTER
$M_DEVL && { 
  check_ver "jhipster" "$VER_JHIPSTER_REQ" "-V | grep -v INFO" verbose || {
    ask "Should I try to install it?" && {
      npm install -g generator-jhipster@$VER_JHIPSTER_DEF
    } || {
      MAYBE_FATAL "Mandatory dependency not available"
    }
  }
}

# ENTANDO-GENERATOR-JHIPSTER (entando blueprint)
$M_DEVL && { 
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
      MAYBE_FATAL "Mandatory dependency not available"
    }
  }
  cd - > /dev/null
}

$M_KUBE && { 
  check_ver "k3s" "$VER_K3S_REQ" "--version 2>/dev/null | sed 's/k3s version \(.*\)+k.*/\1/'" && {
    _log_i 3 "\tfound: $check_ver_res => OK"
  } || {
    ask "Should I try to install it?" && {
      curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$VER_K3S_DEF" sh -
    } || {
      prompt "Recommended dependency not found, some tool may not work as expected.\nPress enter to continue.."
   }
  }
}
