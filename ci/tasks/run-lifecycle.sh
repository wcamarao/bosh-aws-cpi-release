#!/usr/bin/env bash

set -e

source bosh-cpi-release/ci/tasks/utils.sh

check_param aws_access_key_id
check_param aws_secret_access_key
check_param region_name
check_param lifecycle_manual_ip

export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
export AWS_DEFAULT_REGION=${region_name}

stack_name="aws-cpi-stack"
stack_info=$(get_stack_info $stack_name)

export BOSH_AWS_ACCESS_KEY_ID=${aws_access_key_id}
export BOSH_AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
export BOSH_AWS_DEFAULT_KEY_NAME='bats'
export BOSH_AWS_SUBNET_ID=$(get_stack_info_of "${stack_info}" "lifecyclesubnetid")
export BOSH_AWS_SUBNET_ZONE=$(get_stack_info_of "${stack_info}" "lifecycleavailabilityzone")
export BOSH_AWS_LIFECYCLE_MANUAL_IP=${lifecycle_manual_ip}
export BOSH_AWS_ELB_ENDPOINT=$(get_stack_info_of "${stack_info}" "lifecycleelb")
export BOSH_AWS_ELB_ID="bosh-aws-cpi-lifecycle-elb"

export BOSH_CLI_SILENCE_SLOW_LOAD_WARNING=true

source /etc/profile.d/chruby.sh
chruby 2.1.2

cd bosh-cpi-release/src/bosh_aws_cpi

bundle install
bundle exec rspec spec/integration
