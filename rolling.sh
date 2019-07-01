#!/bin/bash

me=$(basename $0)

msg() {
	echo $me: $@
}

die() {
	msg $@
	exit 1
}

hash jq || die "missing tool jq"

[ -n "$ASG" ] || die "missing env var ASG=[$ASG]"
asg="$ASG"

cat <<__EOF__
ASG=$asg
__EOF__

msg increasing auto-scaling-group size to 4
aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$asg" --max-size 4 --desired-capacity 4

list_instances() {
	aws autoscaling describe-auto-scaling-instances | jq -r ".AutoScalingInstances[] | select(.AutoScalingGroupName==\"$asg\" and .HealthStatus==\"HEALTHY\" and .LifecycleState==\"InService\") | .InstanceId"
}

count_instances() {
	list_instances | wc -l
}

check() {
	count=$(count_instances)
	msg $(date) - waiting 4 instances: $count
}

check
while [ "$count" -lt 4 ]; do
	sleep 10
	check
done

msg restoring auto-scaling-group size to 2
aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$asg" --max-size 2 --desired-capacity 2

