#!/bin/bash

NS="$1"
[ "$NS" == "" ] && NS="$ENTANDO_NAMESPACE"
[ "$NS" == "" ] && echo "please provide the namespace name" 1>&2 && exit 1

mkdir -p tmp
cd tmp

echo "" > basics.txt

# DNS rebinding protection TEST
echo "## DNS rebinding protection TEST" >> basics.txt
echo "# Test 1:"
dig +short 192.168.1.1.nip.io >> basics.txt 2>&1
echo "# Test 2:"
dig +short 192.168.1.1.nip.io @8.8.8.8 >> basics.txt 2>&1
echo "" >> basics.txt

# Local info
echo "## LOCAL INFO" >> basics.txt
echo "# Hostname" >> basics.txt
hostname -I >> basics.txt 2>&1
echo "# OS Info" >> basics.txt
lsb_release -a >> basics.txt 2>/dev/null
cat /etc/os-release >> basics.txt 2>&1
echo "# Routes" >> basics.txt
ip r s >> basics.txt 2>&1

# PODs informations collection
echo "## K8S INFO" >> basics.txt

for pod in $(sudo kubectl get pods -n entando | awk 'NR>1' | awk '{print $1}'); do
   echo "> POD: $pod"
   sudo kubectl describe pods/"$pod" -n "$NS" 1> "$pod.describe.txt" 2>&1
   for co in $(sudo kubectl get pods/"$pod" -o jsonpath='{.spec.containers[*].name}{"\n"}' -n "$NS"); do
     echo -e ">\tCONTAINER: $co"
     sudo kubectl logs pods/"$pod" -c "$co" -n "$NS" 1> "$pod-$co.logs.txt" 2>&1
   done
done

cd ..
tar cfz entando-diagdata.tgz tmp/
