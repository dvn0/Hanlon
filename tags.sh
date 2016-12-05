#!/bin/bash
( UUID=$(hanlon tag add -n 1 -t 1 | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.1)&

( UUID=$(hanlon tag add -n 2 -t 2 | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.2)&

( UUID=$(hanlon tag add -n 3 -t 3 | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.3)&

( UUID=$(hanlon tag add -n 4 -t 4 | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.4)&
