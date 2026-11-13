#!/bin/sh
set -eu

/usr/sbin/nginx -t
/bin/systemctl reload nginx
