#!/bin/bash

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Symbols
CHECK="${GREEN}\xE2\x9C\x94${NC}"
CROSS="${RED}\xE2\x9C\x98${NC}"
ARROW="${CYAN}\xE2\x96\xB6${NC}"
BROOM="${YELLOW}\xF0\x9F\xA7\xB9${NC}"

# Title
echo ""
echo -e "${YELLOW} ▄▄ • ▪  ▄▄▄▄▄     ▄▄· ▄▄▌  ▄▄▄ . ▄▄▄·  ▐ ▄ ${NC}"
echo -e "${YELLOW}▐█ ▀ ▪██ •██      ▐█ ▌▪██•  ▀▄.▀·▐█ ▀█ •█▌▐█${NC}"
echo -e "${YELLOW}▄█ ▀█▄▐█· ▐█.▪    ██ ▄▄██▪  ▐▀▀▪▄▄█▀▀█ ▐█▐▐▌${NC}"
echo -e "${YELLOW}▐█▄▪▐█▐█▌ ▐█▌·    ▐███▌▐█▌▐▌▐█▄▄▌▐█ ▪▐▌██▐█▌${NC}"
echo -e "${YELLOW}·▀▀▀▀ ▀▀▀ ▀▀▀     ·▀▀▀ .▀▀▀  ▀▀▀  ▀  ▀ ▀▀ █▪${NC}"
echo -e "${DIM}────────────────────────────────────────────────${NC}"
echo ""

if [ "$1" = "--help" ]; then
  echo -e "  ${BOLD}Usage:${NC} git-clean ${DIM}[command]${NC}"
  echo ""
  echo -e "  ${BOLD}Commands:${NC}"
  echo -e "    ${CYAN}reset${NC} ${DIM}[branch]${NC}  Checkout a branch ${DIM}(default: main)${NC} and clean stale branches"
  echo ""
  echo -e "  ${BOLD}Examples:${NC}"
  echo -e "    ${DIM}\$${NC} git-clean"
  echo -e "    ${DIM}\$${NC} git-clean reset"
  echo -e "    ${DIM}\$${NC} git-clean reset develop"
  echo ""
  exit 0
fi

# Use git rev-parse --is-inside-work-tree to check if we are in a git repo
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
  echo -e "  ${CROSS} ${RED}Not a git repository.${NC}"
  echo ""
  exit 0
fi

# Handle reset subcommand: checkout primary branch then clean
if [ "$1" = "reset" ]; then
  primary_branch="${2:-main}"

  if ! git show-ref --verify --quiet "refs/heads/$primary_branch"; then
    echo -e "  ${CROSS} ${RED}Branch '${BOLD}${primary_branch}${NC}${RED}' does not exist.${NC}"
    echo ""
    exit 1
  fi

  echo -e "  ${ARROW} Checking out ${BOLD}${primary_branch}${NC}..."
  git checkout "$primary_branch" --quiet

  if [ $? -ne 0 ]; then
    echo -e "  ${CROSS} ${RED}Failed to checkout ${BOLD}${primary_branch}${NC}${RED}. Do you have uncommitted changes?${NC}"
    echo ""
    exit 1
  fi

  echo -e "  ${CHECK} Switched to ${BOLD}${primary_branch}${NC}"
  echo ""
fi

# Fetch
echo -e "  ${ARROW} Fetching from remote..."
git fetch --prune --quiet
echo -e "  ${CHECK} Fetch complete"
echo ""

# Iterate
branches=()

for branch in $(git branch -vv | grep ': gone]' | grep -v '*' | awk '{print $1}'); do
  branches+=($branch)
done

# No branches? No problem
if [ ${#branches[@]} == 0 ]; then
  echo -e "  ${CHECK} ${GREEN}Already clean — no stale branches found.${NC}"
  echo ""
  exit 0
fi

# There are some branches
echo -e "  ${BROOM} Found ${BOLD}${#branches[@]}${NC} stale branch(es) ${DIM}(gone on remote)${NC}:"
echo ""

for branch in ${branches[*]}; do
  echo -e "    ${DIM}-${NC} ${branch}"
done

echo ""
echo -e "  ${YELLOW}Delete these branches?${NC} ${DIM}(y/n)${NC} \c"

read response

echo ""

if [ "$response" = "y" ]; then
  for branch in ${branches[*]}; do
    git branch -D $branch --quiet
    echo -e "  ${CHECK} Deleted ${DIM}${branch}${NC}"
  done

  echo ""
  echo -e "  ${CHECK} ${GREEN}All clean!${NC}"
else
  echo -e "  ${CROSS} ${DIM}Aborted — Suit yourself!${NC}"
fi

echo ""
