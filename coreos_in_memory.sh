#!/bin/bash
IMAGE_UUID=$(hanlon image | grep XXXcoreosXXX | tail -1 | awk '{print $1}') \
 || hanlon image add -t os -p ./web/coreos_production_iso_image.iso -v  557 -n XXXcoreosXXX \
    && IMAGE_UUID=$(hanlon image | grep XXXcoreosXXX | tail -1 | awk '{print $1}')

hanlon model add --template coreos_in_memory --label YYYcoreos_in_memoryYYY --image-uuid $IMAGE_UUID -o coreos_in_memory.yml
MODEL_UUID=$(hanlon model | grep YYYcoreos_in_memoryYYY | awk '{print $5}')
hanlon policy add --template linux_deploy --label ZZZcoreos_in_memoryZZZ --model-uuid $MODEL_UUID  --broker-uuid=none -e true --tags 1

