IMAGE_UUID=$(hanlon image | grep core | awk '{print $1}')
hanlon model add --template coreos_stable --label install_coreos --image-uuid $IMAGE_UUID -o coreos-model.yml
MODEL_UUID=$(hanlon model | grep coreos | awk '{print $5}')
hanlon policy add --template linux_deploy --label coreos --model-uuid $MODEL_UUID  --broker-uuid=none -e true --tags 00000000-0000-0000-0000-002590979F58
