#!/usr/bin/env bash

for file in /usr/share/mqtt-scripts/*.sub; do
    # TODO: Make this ignore .pub files? Or maybe I just use *.sub.
    if [ "$file" == "/usr/share/mqtt-scripts/init.sh" ] ; then
        continue;
    fi
    source $file &
done