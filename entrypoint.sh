#!/bin/bash
set -e

echo "Starting SSHD..."
service ssh start

echo "Executing start-hadoop.sh as hadoop user..."
exec gosu hadoop /usr/local/bin/start-hadoop.sh "$@"