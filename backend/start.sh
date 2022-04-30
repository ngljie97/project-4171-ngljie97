#!/bin/bash
app="ketsu_server"
docker build -t ${app} .
docker run -d -p 56733:80 \
  --name=${app} \
  --gpus all \
  -v "${PWD}:/app" ${app}
