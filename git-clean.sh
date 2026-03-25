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
  echo -e "${YELLOW}Usage:${NC} git-clean [reset [branch]]"
  echo -e "  ${YELLOW}reset${NC}  Checkout the given branch (default: main) and clean stale branches"
  exit 0
fi

# Use git rev-parse --is-inside-work-tree to check if we are in a git repo
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
  echo -e "${RED}Oops! The current directory does not contain a git repo.${NC}"
  exit 0
fi

# Handle reset subcommand: checkout primary branch then clean
if [ "$1" = "reset" ]; then
  primary_branch="${2:-main}"

  if ! git show-ref --verify --quiet "refs/heads/$primary_branch"; then
    echo -e "${RED}Branch '${primary_branch}' does not exist.${NC}"
    exit 1
  fi

  echo -e "${YELLOW}Checking out ${primary_branch}...${NC}"
  git checkout "$primary_branch" --quiet

  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to checkout ${primary_branch}. Do you have uncommitted changes?${NC}"
    exit 1
  fi

  echo -e "${GREEN}Switched to ${primary_branch}.${NC}"
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
