#!/bin/bash

cd /app
rm tmp/pids/*

set -e
rails server -b 0.0.0.0 -p 3003 

