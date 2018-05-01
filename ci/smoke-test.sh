#!/bin/bash

set -eux

# This is here so that the bootstrap concourse can
# properly smoke test that things are up.  By default,
# it seems to not have bosh dns working.
if [ ! -z "${DNS_SERVERS}" ] ; then
  cp /etc/resolv.conf /tmp/$$.etc.resolv.conf
  echo "" > /etc/resolv.conf
  for i in ${DNS_SERVERS} ; do
    echo "nameserver $i" >> /etc/resolv.conf
  done
  cat /tmp/$$.etc.resolv.conf >> /etc/resolv.conf
  rm /tmp/$$.etc.resolv.conf
fi
curl -o fly "${ATC_URL}/api/v1/cli?arch=amd64&platform=linux"
chmod +x ./fly

(
  set +x
  ./fly --target ci login \
    --concourse-url "${ATC_URL}" \
    --username "${BASIC_AUTH_USERNAME}" \
    --password "${BASIC_AUTH_PASSWORD}"
)

cat > config.yml << EOF
platform: linux

image_resource:
  type: docker-image
  source:
    repository: busybox

run:
  path: echo
  args: ["smoke"]
EOF

output=$(./fly --target ci execute --config ./config.yml)

if ! echo "${output}" | grep smoke; then
  echo "Expected to find 'smoke' in output"
  exit 1
fi
