#!/usr/bin/env bash

echo "DOMAIN: ${DOMAIN}"
echo "rDir:   ${rDir}"
echo "pDir:   ${pDir}"

d_=${rDir}/social-app
p_=${pDir}/161-social-app-docker-include-curl.diff

pushd ${d_}

echo "applying patch: under ${d_} for ${p_}"
patch -p1 <  ${p_}

popd
