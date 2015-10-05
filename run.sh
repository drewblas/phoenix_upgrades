#!/bin/bash

# Copyright 2015 Drew Blas <drew.blas@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# set -e noerrexit

versions=("0.14.0" "0.15.0" "0.16.0" "0.16.1" "0.17.0" "0.17.1" "1.0.0" "1.0.1" "1.0.2" "1.0.3")

function usage {
  echo "Usage : $0 CMD"
  echo
  echo "Commands: "
  echo
  echo "$0 download - Downloads all the *.ez files for all phoenix versions"
  echo "$0 build [VERSION]- Build a single phoenix version and commit it to git"
  echo "$0 build - Loops through all phoenix versions, building them and committing them to git"
  echo "$0 reset - Erases .git and re-initializes the repo"
}

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

function download_all {
  mkdir -p ez
  cd ez
  for v in "${versions[@]}"
  do
    if [ ! -f phoenix_new-${v}.ez ]; then
      wget https://github.com/phoenixframework/phoenix/releases/download/v${v}/phoenix_new-${v}.ez
    fi
  done
}

function reset {
  rm -rf .git
  git init
  git add .gitignore
  git add README.md
  git add run.sh
  git commit -m "Initial commit"
}

function build {
  rm -rf upgrade
  rm -rf ~/.mix/archives/phoenix_new*

  mix archive.install ez/phoenix_new-$1.ez --force

  echo n | mix phoenix.new upgrade

  #### App Operations
  pushd upgrade
  mix do deps.get, compile

  mix phoenix.gen.model User users name:string age:integer
  mix phoenix.gen.html Post posts user_id:references:users title:string body:text tags:array:string
  mix phoenix.gen.json Comment comments body:text user_id:references:users
  mix phoenix.gen.channel Room rooms

  mv priv/repo/migrations/*_create_user.exs priv/repo/migrations/1_create_user.exs
  mv priv/repo/migrations/*_create_post.exs priv/repo/migrations/2_create_post.exs
  mv priv/repo/migrations/*_create_comment.exs priv/repo/migrations/3_create_comment.exs

  sed -i '' 's/secret_key_base.*/secret_key_base: "REMOVED",/' config/config.exs
  sed -i '' 's/signing_salt.*/signing_salt: "REMOVED"/' lib/upgrade/endpoint.ex

  popd
  #### End App Operations


  git add -A upgrade

  git commit -m "Phoenix v$1"
}

function build_all {
  for v in "${versions[@]}"
  do
    build $v
  done
}

case $1 in
    download)
      echo "Downloading all"
      download_all
    ;;
    build)
      if [ -z $2 ]; then
        echo "Build all"
        build_all
      else
        echo "Build $2"
        build $2
      fi
    ;;
    reset)
      echo "Reset"
      reset
    ;;
    *)
      usage
      exit 1
    ;;
esac
