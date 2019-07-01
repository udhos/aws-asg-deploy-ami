#!/bin/bash

me=$(basename "$0")

msg() {
	echo >&2 "$me: $*"
}

die() {
	msg "$@"
	exit 1
}

usage() {
	echo >&2 usage: "$me" ami
}

if [ $# -lt 1 ]; then
	usage 
	exit 1
fi

ami="$1"

[ -n "$LC_PREFIX" ] || die "missing env var LC_PREFIX=[$LC_PREFIX]"
[ -n "$INSTANCE_ROLE" ] || die "missing env var INSTANCE_ROLE=[$INSTANCE_ROLE]"
[ -n "$ASG" ] || die "missing env var ASG=[$ASG]"
[ -n "$LINKED_ROLE_ARN" ] || die "missing env var LINKED_ROLE_ARN=[$LINKED_ROLE_ARN]"
[ -n "$SECURITY_GROUP" ] || die "missing env var SECURITY_GROUP=[$SECURITY_GROUP]"
[ -n "$SUBNETS" ] || die "missing env var SUBNETS=[$SUBNETS] subnet1,subnet2"
[ -n "$ZONES" ] || die "missing env var ZONES=[$ZONES] 'sa-east-1a sa-east-1c'"

lc_name="$LC_PREFIX"-$(date +%Y%m%d-%H%M%S)
instance_type=t3.micro
security_group="$SECURITY_GROUP"
role="$INSTANCE_ROLE"
asg="$ASG"
asg_linked_role_arn="$LINKED_ROLE_ARN"
subnets="$SUBNETS"
zones="$ZONES"

# shellcheck disable=SC2153
[ -n "$INSTANCE_TYPE" ] && instance_type="$INSTANCE_TYPE"

cat <<__EOF__
INSTANCE_TYPE=$instance_type
launch configuration: $lc_name
auto scaling group:   $asg
__EOF__

aws autoscaling create-launch-configuration --launch-configuration-name "$lc_name" \
	--image-id "$ami" \
	--instance-type "$instance_type" \
	--security-groups "$security_group" \
	--iam-instance-profile "$role" \
	--instance-monitoring Enabled=false

aws autoscaling update-auto-scaling-group --auto-scaling-group-name "$asg" \
	--launch-configuration-name "$lc_name" \
	--min-size 2 \
	--max-size 2 \
	--desired-capacity 2 \
	--default-cooldown 60 \
	--availability-zones "$zones" \
	--health-check-type ELB \
	--health-check-grace-period 60 \
	--vpc-zone-identifier "$subnets" \
	--service-linked-role-arn "$asg_linked_role_arn"

	

