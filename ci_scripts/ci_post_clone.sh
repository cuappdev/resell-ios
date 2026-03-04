#
//  ci_post_clone.sh
//  Resell
//
//  Created by Andrew Gao on 3/4/26.
//

set -e

# Install Minio Client
brew install minio-mc

# Sync secrets from DigitalOcean Spaces
mc alias set my-space https://nyc3.digitaloceanspaces.com "$SPACES_ACCESS_KEY_ID" "$SPACES_SECRET_ACCESS_KEY"
if [[ "$CI_XCODE_CLOUD" == "TRUE" ]]; then
  mc mirror my-space/appdev-upload/ios-secrets/resell/ "$CI_PRIMARY_REPOSITORY_PATH/Resell/Supporting"
else
  mc mirror my-space/appdev-upload/ios-secrets/resell/ "$CI_WORKSPACE/Resell/Supporting"
fi

