#!/bin/bash
cd /home/hanlon/chef-provisioning-k8s
ln -s ../Chef/.chef .
sleep 15
bundle exec chef provision k8s --policy-name k8s 2>&1