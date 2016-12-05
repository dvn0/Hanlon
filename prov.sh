#!/bin/bash
#hanlon image add -t mk -p ./hnl_mk_debug-image.2.0.1.iso

#UUID=$(hanlon tag add -n 1 -t 1 | grep UUID | awk '{print $3}')
#hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.1

#UUID=$(hanlon tag add -n 2 -t 2 | grep UUID | awk '{print $3}')
# hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.2

# UUID=$(hanlon tag add -n 3 -t 3 | grep UUID | awk '{print $3}')
# hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.3

# UUID=$(hanlon tag add -n 4 -t 4 | grep UUID | awk '{print $3}')
# hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.4

# UUID=$(hanlon tag add -n 5 -t 5 | grep UUID | awk '{print $3}')
# hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.5

# UUID=$(hanlon tag add -n 6 -t 6 | grep UUID | awk '{print $3}')
# hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.6

# Pair 'A'
UUID=$(hanlon tag add -n 1A -t A | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.1

UUID=$(hanlon tag add -n 2A -t A | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.2

# Pair 'B'
UUID=$(hanlon tag add -n 3B -t B | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.3

UUID=$(hanlon tag add -n 4B -t B | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.4

# Pair 'C'
UUID=$(hanlon tag add -n 5C -t C | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.5

UUID=$(hanlon tag add -n 6C -t C | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.6

# https://github.com/csc/Hanlon/pull/329
# http://stable.release.core-os.net/amd64-usr/557.2.0/coreos_production_iso_image.iso

#hanlon image add -t os -p ./coreos_production_iso_image.iso -v  557 -n coreos557
IMAGE_UUID=$(hanlon image | grep coreos | awk '{print $1}')
hanlon model add --template coreos_stable --label install_coreos --image-uuid $IMAGE_UUID -o coreos-model.yml
MODEL_UUID=$(hanlon model | grep coreos | awk '{print $5}')
hanlon policy add --template linux_deploy --label coreos --model-uuid $MODEL_UUID  --broker-uuid=none -e true --tags A


# http://mirrors.cat.pdx.edu/centos/6.6/isos/x86_64/CentOS-6.6-x86_64-minimal.iso


#hanlon image add -t os -p ./CentOS-6.6-x86_64-minimal.iso -v 6.6 -n centos6
#IMAGE_UUID=$(hanlon image | grep centos6 | awk '{print $1}')
hanlon model add --template centos_6 --label install_centos6 --image-uuid $IMAGE_UUID --option centos6.yml
#MODEL_UUID=$(hanlon model | grep centos6 | awk '{print $6}')
hanlon policy add --template linux_deploy --label centos6 --model-uuid $MODEL_UUID  --broker-uuid=none -e true --tags B
