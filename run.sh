#!/bin/sh
docker run -h graphite -p 222:22 --name graphite -d levkov/graphite
