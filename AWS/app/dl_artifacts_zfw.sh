#!/bin/bash

/usr/bin/gh auth login --with-token <<<$1
asset=$(/usr/bin/gh api /repos/netfoundry/zfw/actions/artifacts --jq ".artifacts[$2] .archive_download_url")
/usr/bin/curl -Ls  "$asset"    -H "Accept: application/vnd.github.v3+json"    -H "Authorization: Bearer $1"  --output /opt/netfoundry/artifact.zip
/usr/bin/unzip  -d /opt/netfoundry/ /opt/netfoundry/artifact.zip
/usr/bin/dpkg -i /opt/netfoundry/zfw-router_*_amd64.deb