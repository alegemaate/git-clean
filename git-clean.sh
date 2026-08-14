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
  echo -e "  ${BOLD}Options:${NC}"
  echo -e "    ${CYAN}--prune-worktrees${NC}  Prune stale/prunable worktree metadata and paths"
  echo ""
  echo -e "  ${BOLD}Examples:${NC}"
  echo -e "    ${DIM}\$${NC} git-clean"
  echo -e "    ${DIM}\$${NC} git-clean --prune-worktrees"
  echo -e "    ${DIM}\$${NC} git-clean reset"
  echo -e "    ${DIM}\$${NC} git-clean reset develop --prune-worktrees"
  echo ""
  exit 0
fi

prune_worktrees=0
for arg in "$@"; do
  if [ "$arg" = "--prune-worktrees" ]; then
    prune_worktrees=1
  fi
done

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
    echo -e "  ${CROSS} ${RED}Failed to checkout ${BOLD}${primary_branch}${NC}${RED}. It may be checked out in another worktree or you have uncommitted changes.${NC}"
    echo ""
    exit 1
  fi

  echo -e "  ${ARROW} Pulling latest changes for ${BOLD}${primary_branch}${NC}..."
  git pull --quiet

  if [ $? -ne 0 ]; then
    echo -e "  ${CROSS} ${RED}Failed to pull latest changes for ${BOLD}${primary_branch}${NC}${RED}. Do you have uncommitted changes?${NC}"
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

if [ $prune_worktrees -eq 1 ]; then
  echo -e "  ${ARROW} Pruning stale worktrees..."

  prune_output=$(git worktree prune --expire now --verbose 2>&1)
  prune_exit_code=$?

  if [ $prune_exit_code -ne 0 ]; then
    echo -e "  ${CROSS} ${RED}Failed to prune worktrees.${NC}"
    if [ -n "$prune_output" ]; then
      echo "$prune_output"
    fi
    echo ""
    exit 1
  fi

  if [ -n "$prune_output" ]; then
    echo "$prune_output"
  fi

  echo -e "  ${CHECK} Worktree prune complete"
  echo ""
fi

# Build a set of branches currently checked out in any worktree.
worktree_branches=()
while IFS= read -r line; do
  case "$line" in
    "branch refs/heads/"*)
      worktree_branches+=("${line#branch refs/heads/}")
      ;;
  esac
done < <(git worktree list --porcelain)

# Detect worktrees whose checked-out branch upstream is gone.
stale_worktree_entries=()
while IFS='|' read -r wt_branch wt_path wt_prunable; do
  [ -z "$wt_branch" ] && continue

  upstream_track=$(git for-each-ref "refs/heads/$wt_branch" --format='%(upstream:track)')
  if [[ "$upstream_track" == *"[gone]"* ]]; then
    stale_worktree_entries+=("$wt_branch|$wt_path|$wt_prunable")
  fi
done < <(
  git worktree list --porcelain | awk '
    BEGIN { path=""; branch=""; prunable=0 }
    $1 == "worktree" {
      if (path != "") {
        print branch "|" path "|" prunable
      }
      path = substr($0, 10)
      branch = ""
      prunable = 0
      next
    }
    $1 == "branch" {
      branch = $2
      sub(/^refs\/heads\//, "", branch)
      next
    }
    $1 == "prunable" {
      prunable = 1
      next
    }
    END {
      if (path != "") {
        print branch "|" path "|" prunable
      }
    }
  '
)

# Iterate stale local branches (upstream is gone) and skip worktree branches.
branches=()
skipped_worktree_branches=()
while IFS= read -r branch; do
  [ -z "$branch" ] && continue

  in_worktree=0
  for wt_branch in "${worktree_branches[@]}"; do
    if [ "$branch" = "$wt_branch" ]; then
      in_worktree=1
      break
    fi
  done

  if [ $in_worktree -eq 1 ]; then
    skipped_worktree_branches+=("$branch")
  else
    branches+=("$branch")
  fi
done < <(git for-each-ref refs/heads --format='%(refname:short) %(upstream:track)' | awk '/\[gone\]/{print $1}')

# Tell the user if stale branches were skipped because they are checked out in a worktree.
if [ ${#skipped_worktree_branches[@]} -gt 0 ]; then
  echo -e "  ${ARROW} Skipping ${BOLD}${#skipped_worktree_branches[@]}${NC} stale branch(es) checked out in a worktree:"
  for branch in "${skipped_worktree_branches[@]}"; do
    echo -e "    ${DIM}-${NC} ${branch}"
  done
  echo ""
fi

if [ ${#stale_worktree_entries[@]} -gt 0 ]; then
  echo -e "  ${ARROW} Found ${BOLD}${#stale_worktree_entries[@]}${NC} stale worktree branch(es):"
  for entry in "${stale_worktree_entries[@]}"; do
    wt_branch="${entry%%|*}"
    rest="${entry#*|}"
    wt_path="${rest%%|*}"
    wt_prunable="${entry##*|}"

    if [ "$wt_prunable" = "1" ]; then
      echo -e "    ${DIM}-${NC} ${wt_branch} ${DIM}(${wt_path}; prunable)${NC}"
    else
      echo -e "    ${DIM}-${NC} ${wt_branch} ${DIM}(${wt_path})${NC}"
    fi
  done
  echo -e "  ${DIM}Tip:${NC} remove/update those worktrees before deleting their branches."
  echo ""
fi

# No branches? No problem
if [ ${#branches[@]} == 0 ]; then
  echo -e "  ${CHECK} ${GREEN}No deletable stale local branches found.${NC}"
  echo ""
  exit 0
fi

# There are some branches
echo -e "  ${BROOM} Found ${BOLD}${#branches[@]}${NC} stale branch(es) ${DIM}(gone on remote)${NC}:"
echo ""

for branch in "${branches[@]}"; do
  echo -e "    ${DIM}-${NC} ${branch}"
done

echo ""
echo -e "  ${YELLOW}Delete these branches?${NC} ${DIM}(y/n)${NC} \c"

read response

echo ""

if [ "$response" = "y" ]; then
  for branch in "${branches[@]}"; do
    git branch -D "$branch" --quiet
    echo -e "  ${CHECK} Deleted ${DIM}${branch}${NC}"
  done

  echo ""
  echo -e "  ${CHECK} ${GREEN}All clean!${NC}"
else
  echo -e "  ${CROSS} ${DIM}Aborted — Suit yourself!${NC}"
fi

echo ""
