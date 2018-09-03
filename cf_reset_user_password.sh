#!/bin/sh
# Script to reset cf user password

# Print usage
usage () {
    echo
    echo "  Usage: $0 [email] [password]"
    echo
}

# Verify args
if [ "$1x" == "x" ] || [ "$2x" == "x" ]; then
    usage
    exit 1;
fi

# Get token
uaac target https://uaa.grc-apps.svc.ice.ge.com
uaac token client get sst_support -s yYEl4GM5WYPq9g==

# Reset password
uaac password set $1 -p $2

if [ $? -ne 0 ]; then
    echo "ERROR: Password reset failed"
else
    echo "Password was reset for $1"
fi
