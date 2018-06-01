#!/bin/bash

grep -s '^Threads' /proc/[0-9]*/status | awk '{ sum += $2; } END { print sum; }'
