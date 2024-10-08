#!/bin/bash

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Title
echo -e "${YELLOW} ▄▄ • ▪  ▄▄▄▄▄     ▄▄· ▄▄▌  ▄▄▄ . ▄▄▄·  ▐ ▄ ${NC}"
echo -e "${YELLOW}▐█ ▀ ▪██ •██      ▐█ ▌▪██•  ▀▄.▀·▐█ ▀█ •█▌▐█${NC}"
echo -e "${YELLOW}▄█ ▀█▄▐█· ▐█.▪    ██ ▄▄██▪  ▐▀▀▪▄▄█▀▀█ ▐█▐▐▌${NC}"
echo -e "${YELLOW}▐█▄▪▐█▐█▌ ▐█▌·    ▐███▌▐█▌▐▌▐█▄▄▌▐█ ▪▐▌██▐█▌${NC}"
echo -e "${YELLOW}·▀▀▀▀ ▀▀▀ ▀▀▀     ·▀▀▀ .▀▀▀  ▀▀▀  ▀  ▀ ▀▀ █▪${NC}"

if [ "$1" = "--help" ]; then
  echo -e "${YELLOW}Usage:${NC} git-clean"
  exit 0
fi

# Use git rev-parse --is-inside-work-tree to check if we are in a git repo
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
  echo -e "${RED}Oops! The current directory does not contain a git repo.${NC}"
  exit 0
fi

# Fetch!
echo -e "${YELLOW}Fetching branches${NC}"

git fetch --prune --quiet

# Iterate
branches=()

for branch in $(git branch -vv | grep ': gone]' | grep -v '*' | awk '{print $1}'); do
  branches+=($branch)
done

# No branches? No problem
if [ ${#branches[@]} == 0 ]; then
  echo -e "${GREEN}Your git is already clean!${NC}"
  exit 0
fi

# There are some branches
echo -e "${YELLOW}The following branches have been marked as 'gone' on the origin.${NC}"

# Print the branches
for branch in ${branches[*]}; do
  echo -e " - ${branch}"
done

# Get response
echo -e "${YELLOW}Would you like to remove them locally?${NC} (y/n) \c"

read response

if [ "$response" = "y" ]; then
  for branch in ${branches[*]}; do
    echo -e " - Deleting ${branch}"
    git branch -D $branch --quiet
  done

  echo -e "${GREEN}Your branches have been cleaned!${NC}"
else
  echo -e "${RED}Suit yourself!${NC}"
fi
