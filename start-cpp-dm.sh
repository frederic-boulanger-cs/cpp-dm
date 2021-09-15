#!/bin/sh
# VSCode server
# Connect to http://localhost:8443/
REPO=fred0cs/
IMAGE=cpp-dm
TAG=2021
PORT=8443
URL=http://localhost:${PORT}

if [ -z "$SUDO_UID" ]
then
  # not in sudo
  USER_ID=`id -u`
  USER_NAME=`id -n -u`
else
  # in a sudo script
  USER_ID=${SUDO_UID}
  USER_NAME=${SUDO_USER}
fi

docker run --rm --detach \
  --publish ${PORT}:8443 \
  --volume ${PWD}:/config/workspace:rw \
  --env USERNAME=${USER_NAME} --env USERID=${USER_ID} \
  --name ${IMAGE} \
  ${REPO}${IMAGE}:${TAG}

sleep 5

if [ -z "$SUDO_UID" ]
then
     open -a firefox http://localhost:${PORT} \
  || xdg-open http://localhost:${PORT} \
  || echo "Point your web browser at http://localhost:${PORT}"
else
     su ${USER_NAME} -c "open -a firefox http://localhost:${PORT}" \
  || su ${USER_NAME} -c "xdg-open http://localhost:${PORT}" \
  || echo "Point your web browser at http://localhost:${PORT}"
fi
