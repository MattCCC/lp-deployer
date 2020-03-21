#!/bin/bash
# CONNECT TO REPOS FOR DEPS
#
# Access Composer Repo by using Personal Access Token
# To do so we need to perform series of replacements
# until more proper git protocol solution will be implemented
#
# Required globals:
#   REPLACE_FROM
#   REPLACE_TO
#   PRIV_KEY_GITHUB
#
#   REPLACE_FROM_BITBUCKET
#   REPLACE_TO_BITBUCKET
#   PRIV_KEY_BITBUCKET

source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/utils.sh"

REPLACE_FROM="${REPLACE_FROM//[|]}"
REPLACE_TO="${REPLACE_TO//[|]}"
PRIV_KEY_GITHUB="${PRIV_KEY_GITHUB//[|]}"
REPLACE_FROM_BITBUCKET="${REPLACE_FROM_BITBUCKET//[|]}"
REPLACE_TO_BITBUCKET="${REPLACE_TO_BITBUCKET//[|]}"
PRIV_KEY_BITBUCKET="${PRIV_KEY_BITBUCKET//[|]}"

APP_HOME=$PWD
FILES=( "composer.json" "composer.lock" "wp/wp-content/themes/local-register/composer.json" "wp/wp-content/themes/local-register/composer.lock" "wp/wp-content/themes/local-physio/composer.json" "wp/wp-content/themes/local-physio/composer.lock" "wp/wp-content/themes/local-osteo/composer.json" "wp/wp-content/themes/local-osteo/composer.lock" )

add_key "$PRIV_KEY_GITHUB" "github.com" "id_rsa"
add_key "$PRIV_KEY_BITBUCKET" "bitbucket.org" "id_rsa2"

# Run Composer replacer
# TODO: ssh instead of personal tokens
if [ ! -z "${REPLACE_FROM}" ] ; then

    for f in "${FILES[@]}"
    do
        ff="$APP_HOME/$f"
        file="${f##*/}"
        search="/";

        # Check if contains subdir
        if [[ $f =~ $search ]]; then
            cd $APP_HOME/${f%/*}
        else
            cd ${APP_HOME}
        fi

        debug "Composer Dir $PWD";

        if [ -f "$file" ]; then

            sed -i "s|${REPLACE_FROM}|${REPLACE_TO}|g" ${file}

            sed -i "s|${REPLACE_FROM_BITBUCKET}|${REPLACE_TO_BITBUCKET}|g" ${file}

            debug "$ff found"
        else
            debug "$ff does not exist"
        fi

    done

    cd ${APP_HOME}
fi
