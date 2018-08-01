# hadoop-docker
Hadoop Docker

## master

docker run --rm -it --name master -h master hadoop:3.0.3 /etc/bootstrap.sh -bash

## slave

docker run --rm -it --name slave1 -h slave1 hadoop:3.0.3 /etc/bootstrap.sh -bash
