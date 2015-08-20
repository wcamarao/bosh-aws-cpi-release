#!/usr/bin/env bash

set -e -x

source bosh-cpi-release/ci/tasks/utils.sh

check_param aws_access_key_id
check_param aws_secret_access_key
check_param region_name
check_param base_os

apt-get update
apt-get -y install python
curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py
apt-get -y install groff
apt-get -y install jq
pip install awscli

export_file=cloudformation-${base_os}-exports.sh

export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
export AWS_DEFAULT_REGION=${region_name}

aws cloudformation create-stack \
    --stack-name      ${base_os}-bats \
    --template-body   bosh-cpi-release/ci/assets/cloudformation.template

aws cloudformation describe-stacks > cloudformation_state.json

# exports values into an exports file
echo -e "#!/usr/bin/env bash" >> $export_file
echo -e "export DIRECTOR=$(jq '.Stacks[].Outputs[] | select(.OutputKey=="${base_os}directorvip").OutputValue' cloudformation_state.json)" >> $export_file
echo -e "export VIP=$(jq '.Stacks[].Outputs[] | select(.OutputKey=="${base_os}batsvip").OutputValue' cloudformation_state.json)" >> $export_file
echo -e "export SUBNET_ID=$(jq '.Stacks[].Outputs[] | select(.OutputKey=="subnetid").OutputValue' cloudformation_state.json)" >> $export_file
echo -e "export SECURITY_GROUP_NAME=$(jq '.Stacks[].Outputs[] | select(.OutputKey=="securitygroupname").OutputValue' cloudformation_state.json)" >> $export_file
echo -e "export AVAILABILITY_ZONE=$(jq '.Stacks[].Outputs[] | select(.OutputKey=="availabilityzone").OutputValue' cloudformation_state.json)" >> $export_file
