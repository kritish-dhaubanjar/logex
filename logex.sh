#!/bin/bash

VERSION="logex version 1.0.0"

function help() {
  echo "Usage: logex [OPTION]... [FILE]
logex - Bash script to log and organize git-logs by date & repository.

Options:
  -d, --days       set number of days to log
  -a, --author     set commit author to log (git config user.name)
  -v, --version    print logex version
  -u, --update     update logex
  -h, --help       display this help and exit"
}

function update() {
  echo "sudo rm /usr/local/bin/logex"
  sudo rm /usr/local/bin/logex

  echo "sudo curl -L https://raw.githubusercontent.com/kritish-dhaubanjar/logex/main/logex.sh -o /usr/local/bin/logex && sudo chmod +x /usr/local/bin/logex"
  sudo curl -L https://raw.githubusercontent.com/kritish-dhaubanjar/logex/main/logex.sh -o /usr/local/bin/logex && sudo chmod +x /usr/local/bin/logex
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
  -v | --version)
    echo $VERSION
    exit 0
    ;;
  -h | --help)
    help
    exit 0
    ;;
  -u | --update)
    update
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
  LOG=$(git log --author="$AUTHOR" --all --no-merges --pretty=format:%s --after="$DATE 00:00" --before="$DATE 23:59")

  if [[ ! -z $LOG ]]; then
    echo "$LOG"
  fi
}

function reducer() {
  LOGS="$1"
  GROUP_KEYS=()
  GROUPED_LOGS=()
  UNGROUPED_LOGS=()
  OUTPUT=""

  while IFS= read -r LOG; do
    if [[ $LOG =~ ^([A-Z]+-[0-9]+:* ) ]]; then
      FLAG=true
      MATCH=${BASH_REMATCH[1]}

      for INDEX in ${!GROUP_KEYS[@]}; do
        if [[ $MATCH == ${GROUP_KEYS["$INDEX"]} ]]; then
          FLAG=false
          GROUPED_LOGS[$INDEX]="${GROUPED_LOGS[$INDEX]}\n    ◦ $(sed "s/$MATCH//" <<<"$LOG")"
        fi
      done

      if [[ "$FLAG" == "true" ]]; then
        GROUP_KEYS+=("$MATCH")
        GROUPED_LOGS+=("• $LOG")
      fi
    else
      UNGROUPED_LOGS+=("• $LOG")
    fi
  done <<<"$LOGS"

  for LOG in "${UNGROUPED_LOGS[@]}"; do
    OUTPUT+="$LOG\n"
  done

  for LOG in "${GROUPED_LOGS[@]}"; do
    OUTPUT+="$LOG\n"
  done

  echo -e "$OUTPUT"
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

    LOG_GROUPS=$(reducer "$LOGS")

    echo -e "$LOG_GROUPS\n"
  done

  FLAG=false
done
