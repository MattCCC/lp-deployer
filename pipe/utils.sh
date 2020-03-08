#!/bin/bash

# Begin Standard 'imports'
# set -e
# set -o pipefail

#######################################
# Ensure RSA is proper by converting spaces to new lines
# Globals:
#   None
# Arguments:
#   private key
# Returns:
#   key with new lines instead of spaces
#######################################
format_key() {
    local KEY=$1
    local KEY_TYPE=`echo "$KEY" | sed 's|.*BEGIN\(.*\)-----\s\(.*\)\s-----END\(.*\)|\1|'`
    local KEY=`echo "$KEY" | sed 's|.*BEGIN\(.*\)-----\s\(.*\)\s-----END\(.*\)|\2|'`

    KEY="${KEY// /$'\n'}"

    echo "-----BEGIN${KEY_TYPE}-----
${KEY}
-----END${KEY_TYPE}-----"
}

#######################################
# Add private key to ssh known hosts & starts ssh agent
# Globals:
#   None
# Arguments:
#   private key
#   host domain
#   host file name in .ssh dir
# Returns:
#   key with new lines instead of spaces
#######################################
add_key() {
    local KEY=$1
    local HOST=$2
    local HOSTFILE=$3

    mkdir ~/.ssh/ &>/dev/null
    touch ~/.ssh/known_hosts

    if [ ! -z "${KEY}" ] ; then
        KEY=$(format_key "$KEY")
        ssh-keyscan -t rsa,dsa ${HOST} >> ~/.ssh/known_hosts

        touch ~/.ssh/${HOSTFILE}
        cat > ~/.ssh/${HOSTFILE} <<_EOF_
${KEY}
_EOF_
        chmod 400 ~/.ssh/${HOSTFILE}

        # Start the ssh-agent in bg
        eval $(ssh-agent -s)

        # Add to Git
        ssh-add ~/.ssh/${HOSTFILE} &>/dev/null
        wait
        info "Key added"

    fi
}

# End standard 'imports'
