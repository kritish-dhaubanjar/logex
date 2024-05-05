#!/bin/bash

function help (){
  echo "Usage: logex [OPTION]... [FILE]
logex - Bash script to log and organize git-logs by date & repository.

Options:
  -d, --days       set number of days to log
  -a, --author     set commit author to log (git config user.name)
  -h, --help       display this help and exit"
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
  -d | --days)
    DAYS="$2"
    shift
    shift
    ;;
  -a | --author)
    AUTHOR="$2"
    shift
    shift
  ;;
  -h | --help)
    help
    exit 0
  ;;
  *)
    POSITIONAL_ARGS+=("$1")
    shift
    ;;
  esac
done

function getDate() {
  i=$1

  if [[ $(uname) == "Darwin" ]]; then
    DATE=$(date -v "-$i"d +%F)
  else
    DATE=$(date -d "-$i"day +%F)
  fi

  echo $DATE
}

function setProjectRoot() {
  PROJECT_ROOT=$1

  if [[ -z $PROJECT_ROOT ]]; then
    PROJECT_ROOT=$(pwd)
  elif [[ ! -d $PROJECT_ROOT ]]; then
    echo "$PROJECT_ROOT: No such file or directory"
    exit 1
  else
    cd $PROJECT_ROOT
    PROJECT_ROOT=$(pwd)
  fi

  echo $PROJECT_ROOT
}

function logger() {
  DATE=$1
  AUTHOR=$2
  PROJECT_PATH=$3

  cd $PROJECT_PATH
  LOG=$(git log --author="$AUTHOR" --all --no-merges --pretty=format:%s --after="$DATE 00:00" --before="$DATE 23:59" | sed 's/^/• /')

  if [[ ! -z $LOG ]]; then
    echo "$LOG"
  fi
}

DAYS=${DAYS:-1}
AUTHOR=${AUTHOR:-$(git config user.name)}
PROJECT_ROOT=$(setProjectRoot ${POSITIONAL_ARGS[0]})

if [[ $? -ne 0 ]]; then
  exit 1
fi

cd $PROJECT_ROOT
PROJECT_ROOT_IS_GIT=$(git rev-parse --is-inside-work-tree 2>/dev/null)

if [[ $PROJECT_ROOT_IS_GIT ]]; then
  PROJECTS=($PROJECT_ROOT)
else
  PROJECTS=($(ls -d $PROJECT_ROOT/*/))
fi

for ((i = $DAYS - 1; i >= 0; i--)); do
  FLAG=false
  DATE=$(getDate ${i})

  for PROJECT_PATH in ${PROJECTS[@]}; do
    cd $PROJECT_PATH
    PROJECT_ROOT_IS_GIT=$(git rev-parse --is-inside-work-tree 2>/dev/null)

    if [[ ! $PROJECT_ROOT_IS_GIT ]]; then
      continue
    fi

    PROJECT=$(basename $PROJECT_PATH)
    LOGS=$(logger $DATE "$AUTHOR" $PROJECT_PATH)

    if [[ -z $LOGS ]]; then
      continue
    fi

    if [[ $FLAG == false ]]; then
      [ -t 1 ] && echo -e "\033[0;33m\033[1m\033[4m$DATE\033[0m" || echo "$DATE"

      FLAG=true
    fi

    [ -t 1 ] && echo -e "\033[0;34m\033[1m$PROJECT\033[0m" || echo $PROJECT

    echo -e "$LOGS\n"
  done

  FLAG=false
done
