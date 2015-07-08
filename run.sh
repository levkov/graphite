#!/bin/sh
docker run -h graphite -p 222:22 -p 80:80 -p 2003:2003 --name graphite -d levkov/graphite
