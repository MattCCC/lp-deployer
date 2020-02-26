#!/usr/bin/env bash

DIR=${PWD}
PROVISIONDIR="$DIR/provision"
TAG="v${BITBUCKET_BUILD_NUMBER}"

source "$(dirname "$0")/common.sh"

# Wait for build to finish
wait

date
info "Make $TAG release from $BITBUCKET_BRANCH and deploy to $DEPLOY_URL"

cd ${DIR}
info "Checkout inside of $DIR"
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


date
branch="release-${BITBUCKET_BRANCH}"

if [[ -f ${PROVISIONDIR}/.gitignores/all ]]; then
    info "Apply gitignores"
    cat ${PROVISIONDIR}/.gitignores/all > ${DIR}/.gitignore

    if [[ -f ${PROVISIONDIR}/.gitignores/$branch ]]; then
        cat ${PROVISIONDIR}/.gitignores/$branch >> ${DIR}/.gitignore
        success "Gitignore from $branch from $PROVISIONDIR updated"
        cat ${DIR}/.gitignore
    fi
else
    info "Gitignores not found. Skipped..."
fi


date
info 'Run make build cleanup'
make build-cleanup &> /dev/null
success 'Completed'
wait


date
info 'Run Add Dist by refreshing gitignore'
git rm -r --cached . &> /dev/null
git add -A &> /dev/null
git add app/dist -f &> /dev/null
git commit -m "chore(INBUILD) Add dist"
success 'Completed'
wait


date
info 'Run make remove src'
make remove-src &> /dev/null
wait
git commit -m "chore(INBUILD) Cleanup"
success 'Completed'

date
git status
git log --oneline -5
echo "$(git rev-list --all --count) commits in total"


date
info "Connect to remote"

# Add keys
mkdir ~/.ssh/ &>/dev/null
touch ~/.ssh/known_hosts

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
    ssh-keyscan -p ${PORT} -t rsa,dsa ${DOMAIN} >> ~/.ssh/known_hosts

    # Prepare key
    beginRepFrom="-----BEGIN RSA PRIVATE KEY-----"
    endRepFrom="-----END RSA PRIVATE KEY-----"

    PRIV_KEY_DEPLOY_URL=`echo "$PRIV_KEY_DEPLOY_URL" | sed 's|.*BEGIN.*-----\s\(.*\)\s-----END.*|\1|'`

    # Ensure RSA is proper
    PRIV_KEY_DEPLOY_URL="${PRIV_KEY_DEPLOY_URL// /$'\n'}"

    PRIV_KEY_DEPLOY_URL="${beginRepFrom}
${PRIV_KEY_DEPLOY_URL}
${endRepFrom}"

    touch ~/.ssh/${DOMAIN}

    # Preserve newlines
    cat > ~/.ssh/${DOMAIN} <<_EOF_
${PRIV_KEY_DEPLOY_URL}
_EOF_

    chmod 400 ~/.ssh/${DOMAIN}

    # Start the ssh-agent in bg
    eval $(ssh-agent -s)

    # Add to Git
    ssh-add ~/.ssh/${DOMAIN} &>/dev/null
    wait

    git remote add deploy ${DEPLOY_URL}

    # Push and sanitize msg
    PUSH_MSG="$(git push -f -u deploy ${TAG})"
    echo "${PUSH_MSG//$DEPLOY_URL/replaced}"

    wait

    # Switch to branch
    ssh -p ${PORT} ${SSH_DEST} "cd /$SSH_GIT_DIR; git checkout -f $TAG; rm -rf .nuxt/ node_modules/ dist/; npm i; npm run build; pm2 startOrRestart ecosystem.config.js --only prod &>/dev/null &"
    success 'Deployment Successful'
    wait
fi

