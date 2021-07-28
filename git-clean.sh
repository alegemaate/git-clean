
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
if [ -d "./.git" ]; then
  echo "Directory contains a git repo."


  # Fetch!
  echo -e "${YELLOW}Fetching branches${NC}";

  git fetch --prune --quiet
  # Iterate
  branches=()
  for branch in $(git branch -vv | grep ': gone]' | grep -v '*' | awk '{print $1}'); do 
    branches+=($branch); 
  done;
  # No branches? No problem
  if [ ${#branches[@]} == 0 ]; then
    echo -e "${GREEN}Your git is already clean!${NC}";
    exit 0;
  fi;
  # There are some branches
  echo -e "${YELLOW}The following branches have been marked as 'gone' on the origin.${NC}";
  # Print the branches
  for branch in ${branches[*]}; do 
    echo -e " - ${branch}";
  done;
  # Get response
  echo -e "${YELLOW}Would you like to remove them locally?${NC} (y/n) \c";
  read response;
  if [ "$response" = "y" ]; then
    for branch in ${branches[*]}; do 
      echo -e " - Deleting ${branch}";
      git branch -D $branch --quiet;
    done;
    echo -e "${GREEN}Your branches have been cleaned!${NC}";
  else
    echo -e "${RED}Suit yourself!${NC}";
  fi;
else
  echo -e "${RED}Error! Current directory does not contain a git repo.${NC}";
fi;