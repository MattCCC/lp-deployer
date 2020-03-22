#!/usr/bin/env bash

DIR=${PWD}
PROVISIONDIR="$DIR/provision"
TAG="v${BITBUCKET_BUILD_NUMBER}"

source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/utils.sh"

# Wait for build to finish
wait

checkout_branch() {
    date
    info "$TAG release from $BITBUCKET_BRANCH"

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
    local BRANCH=`git rev-parse --abbrev-ref HEAD`
    info "On branch: $BRANCH"
}

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

deploy_to_remote() {
    local URL=$1
    local PRIV_KEY=$2

    local DOMAIN=`echo "$URL" | sed 's/.*@\(.*\):.*/\1/'`
    local PORT=`echo "$URL" | sed -n 's|.*:\([0-9]*\)\(.*\)|\1|p'`
    local SSH_DEST=`echo "$URL" | sed -n 's|.*\/\(.*\)\:\(.*\)|\1|p'`
    local SSH_GIT_DIR=`echo "$URL" | sed -n 's|.*:\([0-9]*\)\(.*\)|\2|p'`

    date
    info "Connect to remote"

    if [ -z "$DOMAIN" ]; then
        error "Fatal Error: Cannot find deploy url domain"
        exit 126
    elif [ -z "$PORT" ]; then
        error "Fatal Error: Cannot find port in deploy url"
        exit 126
    else
        # Add ssh key to known hosts
        add_key "$PRIV_KEY" "$DOMAIN" "$DOMAIN" "$PORT"

        git remote add ${DOMAIN} ${URL}

        # Push and sanitize msg
        PUSH_MSG="$(git push -f -u ${DOMAIN} ${TAG})"
        echo "${PUSH_MSG//$URL/replaced}"

        wait

        if [ ! -z "$BACKEND" ]; then
            # TODO: connect to ssh to see if repo exists or has to be cloned

            # Backend
            ssh -p ${PORT} ${SSH_DEST} "cd /$SSH_GIT_DIR; git checkout -f $TAG"
        else
            # TODO: list commands in separate exec file and load it from external repo, execute on prod and remove

            # Node server (frontend)
            ssh -p ${PORT} ${SSH_DEST} "cd /$SSH_GIT_DIR; git checkout -f $TAG; rm -rf .nuxt/ node_modules/ dist/; npm i; npm run build; pm2 startOrRestart ecosystem.config.js --only $APP_ENV &>/dev/null &"
        fi

        info 'Proceeded'
        wait
    fi
}

checkout_branch
apply_gitignores
build_cleanup
add_dist
remove_src
print_stats
deploy_to_remote "$DEPLOY_URL" "$PRIV_KEY_DEPLOY_URL"

if [ ! -z "$DEPLOY_URL2" ]; then
    deploy_to_remote "$DEPLOY_URL2" "$PRIV_KEY_DEPLOY_URL2"
fi