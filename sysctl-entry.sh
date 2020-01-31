#!/bin/bash
set -e

sysctl -p

exec "$@"