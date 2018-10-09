
create() {
  local file=$1.yaml
  echo "Creating resource from '$file'..."
  fog create resource -f $file --config config.yaml
  if [ $? -ne 0 ]; then
    echo "Error: Error processing '$file', aborting."
    exit 1
  fi
}

fog context set --path /root

create kubernetes-provider
create kong-provider
create logging-provider
# fog meta patch-provider --provider '/root/default-kubernetes' -f link-logging-provider.json
