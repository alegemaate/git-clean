#!/bin/bash

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Fetch!
echo -e "Fetching branches";
git fetch -p

# Iterate
branches=()

for branch in $(git branch -vv | grep ': gone]' | awk '{print $1}'); do 
  echo -e " ${branch}";
  branches+=($branch); 
done;

# Get response
echo -e "${YELLOW}Are you sure you want to remove the previous branches?${NC} (y/n)";

read response;

if [ "$response" = "y" ]; then
  for branch in ${branches[*]} ; do 
    echo -e " Deleting ${branch}";
    git branch -D $branch;
  done;
fi;
