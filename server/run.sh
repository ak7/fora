#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo switched to $DIR
cd $DIR

./compile.sh $1
echo Fora application starting...

cd app/website

if [ "$1" == "--trace" ]; then
    echo Killing node if it is running..
    killall node
    node --harmony app.js &
else
    forever start -c "node --harmony" app.js
fi
cd ..
