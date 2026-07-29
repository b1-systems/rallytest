#!/bin/bash

docker run --network host --rm -ti \
    -e RALLY_ENV_NAME="${RALLY_ENV_NAME:-openstack-v2}" \
    -v $PWD/db/:/home/rally/.rally/ \
    -v $PWD/envfile:/home/rally/envfile \
    -v $PWD/task_arguments.yaml:/home/rally/task_arguments.yaml \
    rallytest task start task.yaml --task-args-file task_arguments.yaml
