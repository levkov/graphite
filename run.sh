#!/bin/sh
docker run -h graphite -p 222:22 -p 80:80 --name graphite -d levkov/graphite
