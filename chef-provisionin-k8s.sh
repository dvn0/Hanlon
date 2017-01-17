#!/bin/bash
cd /home/chef/chef-provisioning-k8s
ln -s ../Chef/.chef .
bundle exec chef provision k8s --policy-name k8s 2>&1