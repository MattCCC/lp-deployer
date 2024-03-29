#!/bin/bash

# Deploy files using git & ssh
#
# Required globals:
#   CI
#   BITBUCKET_BUILD_NUMBER
#   BITBUCKET_BRANCH
#
#   APP_ENV
#
#   DEPLOY_URL
#   PRIV_KEY_DEPLOY_URL
#
# Optional globals:
#   BACKEND
#   DEBUG
#
#   DEPLOY_URL2
#   PRIV_KEY_DEPLOY_URL2

source "$(dirname "$0")/common.sh"

LFTP_DEBUG_ARGS=""

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

  # Return depending on response
  STATUS=$?

  if [[ "${STATUS}" != "0" ]]; then
    fail "Adding keys Failed. Deployment aborted"
    exit $STATUS
  fi
}

## Only for backend as composer repos keys are required to build properly
install_build_test() {
  if [ ! -z "$BACKEND" ]; then
    make install-verbose
    make build
    make test
  fi
}

deploy() {
    info "Starting deployment..."

    ./provision/deploy.sh

    # Return depending on response
    STATUS=$?

    if [[ "${STATUS}" == "0" ]]; then
      success "Deployment Successful"
    else
      fail "Deployment Failed"
      exit $STATUS
    fi
}

validate
enable_debug
add_repos_keys
install_build_test
deploy

# Keep terminal open
exec "$@"