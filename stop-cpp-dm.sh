#!/bin/sh
# Kill VSCode server container
IMAGE=cpp-dm

docker kill ${IMAGE}
