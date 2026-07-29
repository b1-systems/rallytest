#!/bin/bash

[[ $1 == "" ]] && exit 1

ID=$1
TIMESTAMP="$( date +%F-%s )"

docker run --network host --rm -ti \
    -e RALLY_ENV_NAME="${RALLY_ENV_NAME:-openstack-v2}" \
    -v $PWD/db/:/home/rally/.rally/ \
    -v $PWD/envfile:/home/rally/envfile \
    -v $PWD/task_arguments.yaml:/home/rally/task_arguments.yaml \
    -v $PWD/reports:/home/rally/reports/ rallytest task report $ID --out reports/$TIMESTAMP.html

echo "reports/$TIMESTAMP.html"
