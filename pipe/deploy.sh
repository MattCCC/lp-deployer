#!/usr/bin/env bash

DIR=${PWD}
PROVISIONDIR="$DIR/provision"
TAG="v${BITBUCKET_BUILD_NUMBER}"

source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/utils.sh"

# Wait for build to finish
wait

date
info "Make $TAG release from $BITBUCKET_BRANCH and deploy to $DEPLOY_URL"

cd ${DIR}
info "Checkout inside $DIR"
git checkout -f -b ${TAG}

# Remove untracked
git clean -fd

# Skip LFs to CRLFs warning
git config core.autocrlf true

# In order to commit
git config --global user.email "you@auto.com"
git config --global user.name "Auto"

date
BRANCH=`git rev-parse --abbrev-ref HEAD`
info "On branch: $BRANCH"

apply_gitignores() {
    date
    local branch="release-${BITBUCKET_BRANCH}"

    if [[ -f ${PROVISIONDIR}/.gitignores/all ]]; then
        info "Apply gitignores"
        cat ${PROVISIONDIR}/.gitignores/all > ${DIR}/.gitignore

        # Apply for specific branch
        if [[ -f ${PROVISIONDIR}/.gitignores/$branch ]]; then
            cat ${PROVISIONDIR}/.gitignores/$branch >> ${DIR}/.gitignore
            success "Gitignore for $branch updated from $PROVISIONDIR"
        else
            info "Branch specific gitignore not found. Skipped..."
        fi

        # Apply for all releases
        if [[ -f ${PROVISIONDIR}/.gitignores/release ]]; then
            cat ${PROVISIONDIR}/.gitignores/release >> ${DIR}/.gitignore
            success "Gitignore for release updated from $PROVISIONDIR"
        else
            info "Release gitignore not found. Skipped..."
        fi
    else
        info "Gitignores not found. Skipped..."
    fi

    wait
}

build_cleanup() {
    date
    info 'Run make build cleanup'
    make build-cleanup &> /dev/null
    success 'Completed'
    wait
}

add_dist() {
    date
    info 'Run Add Dist by refreshing gitignore'
    git rm -r --cached . &> /dev/null
    git add -A &> /dev/null
    git add app/dist -f &> /dev/null
    git commit -m "chore(INBUILD) Add dist"
    success 'Completed'
    wait
}

remove_src() {
    date
    info 'Run make remove src'
    make remove-src &> /dev/null
    wait
    git commit -m "chore(INBUILD) Cleanup"
    success 'Completed'
    wait
}

print_stats() {
    date
    git status
    git log --oneline -5
    echo "$(git rev-list --all --count) commits in total"
    wait
}


apply_gitignores
build_cleanup
add_dist
remove_src
print_stats


date
info "Connect to remote"

DOMAIN=`echo "$DEPLOY_URL" | sed 's/.*@\(.*\):.*/\1/'`
PORT=`echo "$DEPLOY_URL" | sed -n 's|.*:\([0-9]*\)\(.*\)|\1|p'`
SSH_DEST=`echo "$DEPLOY_URL" | sed -n 's|.*\/\(.*\)\:\(.*\)|\1|p'`
SSH_GIT_DIR=`echo "$DEPLOY_URL" | sed -n 's|.*:\([0-9]*\)\(.*\)|\2|p'`

if [ -z "$DOMAIN" ]; then
    error "Fatal Error: Cannot find deploy url domain"
    # exit 126
elif [ -z "$PORT" ]; then
    error "Fatal Error: Cannot find port in deploy url"
    # exit 126
else
    # Add ssh key to known hosts
    add_key "$PRIV_KEY_DEPLOY_URL" "$DOMAIN" "$DOMAIN" "$PORT"

    git remote add deploy ${DEPLOY_URL}

    # Push and sanitize msg
    PUSH_MSG="$(git push -f -u deploy ${TAG})"
    echo "${PUSH_MSG//$DEPLOY_URL/replaced}"

    wait

    # Switch to branch
    if [ ! -z "$BACKEND" ]; then
        # Backend
        ssh -p ${PORT} ${SSH_DEST} "cd /$SSH_GIT_DIR; git checkout -f $TAG"
    else
        # Node server (frontend)
        ssh -p ${PORT} ${SSH_DEST} "cd /$SSH_GIT_DIR; git checkout -f $TAG; rm -rf .nuxt/ node_modules/ dist/; npm i; npm run build; pm2 startOrRestart ecosystem.config.js --only $APP_ENV &>/dev/null &"
    fi

    success 'Deployment Successful'
    wait
fi

