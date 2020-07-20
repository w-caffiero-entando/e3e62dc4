#!/bin/bash

[ "$1" == "" ] && echo "please provide the namespace name" 1>&2 && exit 1

NS="$1"

mkdir -p tmp
cd tmp

for pod  in $(sudo kubectl get pods -n entando | awk 'NR>1' | awk '{print $1}'); do
   echo "> POD: $pod"
   sudo kubectl describe pods/"$pod" -n "$NS" 1> "$pod.describe.txt" 2>&1
   for co in $(sudo kubectl get pods/"$pod" -o jsonpath='{.spec.containers[*].name}{"\n"}' -n "$NS"); do
     echo -e ">\tCONTAINER: $co"
     sudo kubectl logs pods/"$pod" -c "$co" -n "$NS" 1> "$pod-$co.logs.txt" 2>&1
   done
done

cd ..
tar cfz entando-diagdata.tgz tmp/
