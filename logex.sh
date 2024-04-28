#!/bin/bash

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
  -d | --days)
    DAYS="$2"
    shift
    shift
    ;;
  *)
    POSITIONAL_ARGS+=("$1")
    shift
    ;;
  esac
done

function getDate() {
  i=$1
  TODAY=$(date +%F)

  # Check if the operating system is macOS or Linux
  if [[ $(uname) == "Darwin" ]]; then
      # macOS
      DATE=$(date -v "-$i"d +%F)
  else
      DATE=$(date -d "$TODAY - $i day" +%F)
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
  fi

  echo $PROJECT_ROOT
}

function setDays() {
  DAYS=$1

  if [[ -z $DAYS ]]; then
    DAYS=1
  fi

  echo $DAYS
}

function logger() {
  DATE=$1
  AUTHOR=$2
  PROJECT_PATH=$3
  PROJECT=$(basename $PROJECT_PATH)

  cd $PROJECT_PATH
  LOG=$(git log --author="$AUTHOR" --all --no-merges --pretty=format:%s --after="$DATE 00:00" --before="$DATE 23:59" | sed 's/^/• /')

  if [[ ! -z $LOG ]]; then
    echo "$LOG"
  fi
}

DAYS=$(setDays $DAYS)
AUTHOR=$(git config user.name)
PROJECT_ROOT=$(setProjectRoot ${POSITIONAL_ARGS[0]})

cd $PROJECT_ROOT
PROJECT_ROOT_IS_GIT=$(git rev-parse --is-inside-work-tree 2>/dev/null)

if [[ $PROJECT_ROOT_IS_GIT ]]; then
  PROJECTS=($PROJECT_ROOT)
else
  PROJECTS=($(ls -d "$PROJECT_ROOT"/*/))
fi

for ((i = $DAYS - 1; i >= 0; i--)); do
  FLAG=false
  DATE=$(getDate ${i})

  for j in ${!PROJECTS[@]}; do
    PROJECT_PATH=${PROJECTS[$j]}

    cd $PROJECT_PATH
    PROJECT_ROOT_IS_GIT=$(git rev-parse --is-inside-work-tree 2>/dev/null)

    if [[ $PROJECT_ROOT_IS_GIT ]]; then
      PROJECT=$(basename $PROJECT_PATH)
      LOGS=$(logger $DATE "$AUTHOR" $PROJECT_PATH)

      if [[ ! -z $LOGS ]]; then
        if [[ $FLAG == false ]]; then
          if [ -t 1 ]; then
            echo -e "\033[0;33m\033[1m\033[4m$DATE\033[0m"
          else
            echo "$DATE"
          fi

          FLAG=true
        fi

        if [ -t 1 ]; then
          echo -e "\033[0;34m\033[1m$PROJECT\033[0m"
        else
          echo $PROJECT
        fi

        echo -e "$LOGS\n"
      fi
    fi
  done

  FLAG=false
done
