#!/usr/bin/env bash

# Wait until container is considered healthy.
timeout 300 bash -c 'until [ "$(docker inspect -f {{.State.Health.Status}} raspbian)" == "healthy" ]; do sleep 10; done'
