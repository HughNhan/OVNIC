#!/bin/bash

num_samples=3
config=$1
placement=./standard-32pairs.placement
if [ -z "$config" ]; then
    echo "config file not specified.  Use ./run.sh <your-config-file>"
    exit 1
fi
if [ ! -e $config ]; then
    echo "Could not find $config, exiting"
    exit 1
fi

if [ ! -e $placement ]; then
    echo "Could not find $placement, exiting"
    exit 1
fi
. $placement
. $config

if [ -z "$tags" ]; then
    echo "You must define tags in your config file"
    exit 1
fi

if [ -z "$ocp_host" ]; then
    echo "You must define ocp_host in your config file"
    exit 1
fi

if [ -z "$num_samples" ]; then
    echo "You must define num_samples in your config file"
    exit 1
fi


ssh $k8susr@$ocp_host "kubectl delete ns crucible-rickshaw"
ssh $k8susr@$ocp_host "kubectl create ns crucible-rickshaw"
# crucible delete NS and thus also delete neworkAttachmentDefinition. Now we need to recreta them.
ssh $k8susr@$ocp_host "kubectl apply -f ${SRIOV_NAD}"

time crucible run iperf,uperf\
 --mv-params iperf-mv-params.json,uperf-mv-params.json\
 --bench-ids iperf:21-26,uperf:1-20,uperf:27-32\
 --tags $tags\
 --num-samples=$num_samples --max-sample-failures=1\
 --endpoint k8s,user:$k8susr,host:$ocp_host,\
\
nodeSelector:client-${worker1_clients}:$pwd/nodeSelector-$worker1.json,\
nodeSelector:server-${worker1_servers}:$pwd/nodeSelector-$worker1.json,\
\
nodeSelector:client-${worker2_clients}:$pwd/nodeSelector-$worker2.json,\
nodeSelector:server-${worker2_servers}:$pwd/nodeSelector-$worker2.json,\
\
nodeSelector:client-${worker3_clients}:$pwd/nodeSelector-$worker3.json,\
nodeSelector:server-${worker3_servers}:$pwd/nodeSelector-$worker3.json,\
userenv:fedora38,\
masters-tool-collect:0,\
client:1-32,\
server:1-32${annotation_opt}${resources_opt}

#runtimeClassName:performance-manual,\
