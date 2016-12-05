#!/bin/bash
# Pair 'A'
(
UUID=$(hanlon tag add -n 1A -t A | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.1
UUID=$(hanlon tag add -n 1 -t 1 | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.1
)&

(
UUID=$(hanlon tag add -n 2A -t A | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.2
UUID=$(hanlon tag add -n 2 -t 2 | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.2
)&

# Pair 'B'
(
UUID=$(hanlon tag add -n 3B -t B | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.3
UUID=$(hanlon tag add -n 3 -t 3 | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.3
)&

(
UUID=$(hanlon tag add -n 4B -t B | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.4
UUID=$(hanlon tag add -n 4 -t 4 | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.4
)&

# Pair 'C'
(
UUID=$(hanlon tag add -n 5C -t C | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.5
UUID=$(hanlon tag add -n 5 -t 5 | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.5
)&

(
UUID=$(hanlon tag add -n 6C -t C | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.6
UUID=$(hanlon tag add -n 6 -t 6 | grep UUID | awk '{print $3}')
hanlon tag $UUID matcher add --key mk_ipmi_IP_Address --compare equal --value 1.1.0.6
)&




