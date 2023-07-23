#!/usr/bin/env bash

namespace=$(ip netns | awk '{print $1}' |head -1)
printf "\n>> sudo ip netns exec $namespace curl http://127.0.0.1:9999"
echo

if ! [ -x "$(command -v python3)" ]; then
    sudo apt-get update -y
    sudo apt-get install python3 -y
fi

sudo ip netns exec $namespace python3 -m http.server 9999
