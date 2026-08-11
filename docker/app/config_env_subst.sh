#!/bin/bash
# Genera /usr/share/nginx/html/conf.json a partir de las variables de
# entorno, igual que hace la imagen oficial de taiga-front en su
# docker-entrypoint.d (AGPL-3.0, ver THIRD_PARTY.md).
#
# Fuente original:
# https://github.com/taigaio/taiga-front/blob/stable/docker/config_env_subst.sh

contribs=()

# Slack
if [[ -z "${ENABLE_SLACK}" ]]; then
    export ENABLE_SLACK="false"
fi

if [ ${ENABLE_SLACK} == "true" ]; then
    contribs+=('"plugins/slack/slack.json"')
fi

# Public registration and oauth
if [[ -z "${PUBLIC_REGISTER_ENABLED}" ]]; then
    export PUBLIC_REGISTER_ENABLED="false"
fi

if [ ${PUBLIC_REGISTER_ENABLED} == "true" ]; then
    if [ ${ENABLE_GITHUB_AUTH} == "true" ]; then
        contribs+=('"plugins/github-auth/github-auth.json"')
    fi
    if [ ${ENABLE_GITLAB_AUTH} == "true" ]; then
        contribs+=('"plugins/gitlab-auth/gitlab-auth.json"')
    fi
fi

# Importers
if [[ -z "${ENABLE_GITHUB_IMPORTER}" ]]; then
    export ENABLE_GITHUB_IMPORTER="false"
fi

if [[ -z "${ENABLE_JIRA_IMPORTER}" ]]; then
    export ENABLE_JIRA_IMPORTER="false"
fi

if [[ -z "${ENABLE_TRELLO_IMPORTER}" ]]; then
    export ENABLE_TRELLO_IMPORTER="false"
fi

# Default language
if [[ -z "${DEFAULT_LANGUAGE}" ]]; then
    export DEFAULT_LANGUAGE="en"
fi

# Debug
if [[ -z "${DEBUG}" ]]; then
    export DEBUG="false"
fi

contribs=$( IFS=,; echo "[${contribs[*]}]" )

export CONTRIB_PLUGINS=$contribs

FILE=/usr/share/nginx/html/conf.json
if [ ! -f "$FILE" ]; then
    envsubst < /usr/share/nginx/html/conf.json.template \
             > /usr/share/nginx/html/conf.json
fi

sed -i 's;<base href="/">;<base href="'"${TAIGA_SUBPATH}/"'">;g' /usr/share/nginx/html/index.html
