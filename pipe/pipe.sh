#!/bin/bash
# Deploy files using git & ssh
#
# Required globals:
#   BITBUCKET_BRANCH
#   APP_ENV
#   DEPLOY_URL
#   CI
#   BITBUCKET_BUILD_NUMBER
#   PRIV_KEY_DEPLOY_URL
#
# Optional globals:
#   BACKEND
#   DEBUG

source "$(dirname "$0")/common.sh"

LFTP_DEBUG_ARGS=
## Enable debug mode.
enable_debug() {
  if [[ "${DEBUG}" == "true" ]]; then
    info "Enabling debug mode."
    set -x
    LFTP_DEBUG_ARGS="-vvv"
  fi
}

validate() {
  # mandatory parameters
  : APP_ENV=${APP_ENV:?'APP_ENV variable missing'}
  : BITBUCKET_BRANCH=${BITBUCKET_BRANCH:?'BITBUCKET_BRANCH variable missing.'}
  : DEPLOY_URL=${DEPLOY_URL:?'DEPLOY_URL variable missing'}
  : CI=${CI:?'CI variable missing'}
  : BITBUCKET_BUILD_NUMBER=${BITBUCKET_BUILD_NUMBER:?'BITBUCKET_BUILD_NUMBER variable missing.'}
  : PRIV_KEY_DEPLOY_URL=${PRIV_KEY_DEPLOY_URL:?'PRIV_KEY_DEPLOY_URL variable missing.'}
}

add_repos_keys() {
  info "Add keys..."

  ./provision/composer.sh
}

deploy() {
    info "Starting deployment..."

    ./provision/deploy.sh

    # Return depending on response
    STATUS=$?

    if [[ "${STATUS}" == "0" ]]; then
      success "Deployment Successful."
    else
      fail "Deployment Failed."
      exit $STATUS
    fi
}

validate
enable_debug
add_repos_keys
deploy

# Keep terminal open
exec "$@"