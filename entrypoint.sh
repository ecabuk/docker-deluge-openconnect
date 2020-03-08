#!/usr/bin/env bash

# Set UID
if [[ ! -z "${PUID}" ]]; then
    usermod -u ${PUID} deluge
fi

# Set GID
if [[ ! -z "${PGID}" ]]; then
    groupmod -g ${PGID} deluge
fi


exec "$@"