#!/bin/bash

# On mydocker
#export PASSWORD=$2
# local
# export PASSWORD="password"

cp -Rn /init-config/* /config/
cp -Rn /init-config/.oh-my-zsh /config/
cp -Rn /init-config/.zshrc /config/

/usr/local/bin/code-server \
	--bind-addr 0.0.0.0:8443 \
	--disable-telemetry \
	--disable-update-check \
	--user-data-dir /config/data \
	--extensions-dir /config/extensions \
	--auth "none" \
	/config/workspace
