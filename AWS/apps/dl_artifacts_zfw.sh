#!/bin/bash

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Check arguments first, before authentication
if [ $# -ne 3 ]; then
  echo "Usage: $0 <github_token> <repo_name> <artifact_type>"
  echo "artifact_type should be: zfw or zfw-router"
  exit 1
fi

GITHUB_TOKEN="$1"
REPO_NAME="$2"
ARTIFACT_TYPE="$3"

echo "Token: ${GITHUB_TOKEN:0:10}...${GITHUB_TOKEN: -2}"
echo "Repo Name: ${REPO_NAME}"
echo "Artifact Type: ${ARTIFACT_TYPE}"

echo "Authenticating with GitHub..."
/usr/bin/gh auth login --with-token <<<"$GITHUB_TOKEN"

# Determine artifact name pattern
case "$ARTIFACT_TYPE" in
  "zfw")
    pattern="zfw-amd64-deb"
    ;;
  "zfw-router")
    pattern="router-amd64-deb"
    ;;
  *)
    echo "Error: artifact_type must be 'zfw' or 'zfw-router'"
    exit 1
    ;;
esac

echo "Looking for artifacts matching pattern: $pattern"

asset=$(/usr/bin/gh api "/repos/netfoundry/$REPO_NAME/actions/artifacts" | jq -r --arg pattern $pattern \
    '(last((.artifacts | sort_by(.created_at))[] | select(.name | endswith($pattern)).archive_download_url))')

if [ -z "$asset" ]; then
    echo "Error: No artifact found matching pattern '$pattern'"
    exit 1
fi

echo "Found asset: $asset"

echo "Downloading artifact..."
/usr/bin/curl -Ls "$asset" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    --output /opt/netfoundry/artifact.zip

echo "Extracting artifact..."
/usr/bin/unzip -o -d /opt/netfoundry/ /opt/netfoundry/artifact.zip

echo "The artifact to be installed is ${ARTIFACT_TYPE}"
if [ "$ARTIFACT_TYPE" == "zfw" ]; then
    echo "Removing existing router/zfw  deb package..."
    /opt/openziti/bin/revert_ebpf_router.py || true
    /usr/bin/dpkg -P zfw-router || true
    /usr/bin/dpkg -P zfw || true
fi

echo "Installing package..."
/usr/bin/dpkg -i /opt/netfoundry/${ARTIFACT_TYPE}_*_amd64.deb

if [ "$ARTIFACT_TYPE" == "zfw" ]; then
    echo "Starting ${ARTIFACT_TYPE} service..."
    /opt/openziti/bin/start_ebpf_router.py || true
fi

echo "Installation complete!"
