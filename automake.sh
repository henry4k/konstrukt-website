#!/bin/bash
while true; do
    make
    inotifywait -e modify -r -q .
done
