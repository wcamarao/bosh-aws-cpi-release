#!/usr/bin/env bash

set -e -x

source bosh-cpi-release/ci/tasks/utils.sh

check_param BAT_VCAP_PASSWORD
check_param BAT_STEMCELL
check_param BAT_DEPLOYMENT_SPEC
check_param BAT_VCAP_PRIVATE_KEY

source /etc/profile.d/chruby.sh
chruby 2.1.2

terraform_statefile_semver=`cat terraform-state-version/number`
source terraform-ubuntu-exports/terraform-ubuntu-exports-${terraform_statefile_semver}.sh

export BAT_DIRECTOR=$UBUNTU_DIRECTOR
export BAT_DNS_HOST=$UBUNTU_DIRECTOR
export BAT_INFRASTRUCTURE=aws
export BAT_NETWORKING=manual
export BAT_VIP=$UBUNTU_VIP
export BAT_SUBNET_ID=$UBUNTU_SUBNET_ID
export BAT_SECURITY_GROUP_NAME=$UBUNTU_SECURITY_GROUP_NAME

eval $(ssh-agent)
chmod go-r $BAT_VCAP_PRIVATE_KEY
ssh-add $BAT_VCAP_PRIVATE_KEY

bosh -n target $BAT_DIRECTOR

sed -i.bak s/"uuid: replace-me"/"uuid: $(bosh status --uuid)"/ $BAT_DEPLOYMENT_SPEC
sed -i.bak s/"vip: replace-me"/"vip: $BAT_VIP"/ $BAT_DEPLOYMENT_SPEC
sed -i.bak s/"subnet: replace-me"/"subnet: $BAT_SUBNET_ID"/ $BAT_DEPLOYMENT_SPEC
sed -i.bak s/"security_groups: replace-me"/"security_groups: [$BAT_SECURITY_GROUP_NAME]"/ $BAT_DEPLOYMENT_SPEC

cd bats
bundle install
bundle exec rspec spec
