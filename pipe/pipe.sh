#!/bin/bash
# Deploy files using git & ssh
#
# Required globals:
#   BITBUCKET_BRANCH
#   DEPLOY_URL
#   CI
#   BITBUCKET_BUILD_NUMBER
#   PRIV_KEY_DEPLOY_URL
#
# Optional globals:
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
  : BITBUCKET_BRANCH=${BITBUCKET_BRANCH:?'BITBUCKET_BRANCH variable missing.'}
  : DEPLOY_URL=${DEPLOY_URL:?'DEPLOY_URL variable missing'}
  : CI=${CI:?'CI variable missing'}
  : BITBUCKET_BUILD_NUMBER=${BITBUCKET_BUILD_NUMBER:?'BITBUCKET_BUILD_NUMBER variable missing.'}
  : PRIV_KEY_DEPLOY_URL=${PRIV_KEY_DEPLOY_URL:="${PRIV_KEY_DEPLOY_URL}"}
}

run_pipe() {
    info "Starting deployment..."

    ./deploy.sh

    # TODO return depending on response
    STATUS=1

    if [[ "${STATUS}" == "0" ]]; then
      success "Deployment finished."
    else
      fail "Deployment failed."
    fi

    exit $STATUS
}

validate
enable_debug
run_pipe