#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

set -o allexport
. "$params_file"
set +o allexport

repoDirs="`make echo | grep ^repoDirs: | sed 's/^repoDirs: //'`"
missingRepos="`for repoDir in ${repoDirs}; do [ -d "$repoDir" ] || echo $repoDir ; done`"
show_heading "Cloning source code" "from the different repositories"
make cloneAll

show_heading "Fetching latest" "from the different repositories"
for repoDir in $repoDirs
  do
    (
      cd $repoDir
      echo "$blue_color$clear_bold`basename ${repoDir}`$reset_color"
      git fetch --all
      git diff --exit-code --stat || { show_error "Uncommitted changes in `basename $repoDir`:" "inspect $repoDir and adjust as necessary" ; exit 1 ; }
      current_branch="`git rev-parse --abbrev-ref HEAD`"
      if [[ "$current_branch" == "main" ]]
        then
          echo already on main branch - fast forwarding
          git merge origin/main
      elif [[ "$current_branch" == "work" || "$current_branch" == "dockerbuild" || "$current_branch" == "local-rebranding-$REBRANDING_NAME" ]]
        then
          echo switching from branch $current_branch to main
          git checkout main
          git merge origin/main
        else
          show_error "Unexpected branch in `basename "$repoDir"`:" "$current_branch - inspect $repoDir and adjust as necessary"
          exit 1
        fi
    ) || { echo aha; exit 1; }
  done

if [ "$missingRepos" != "" ]
  then
    show_heading "Making work branches" "for the different repositories"
    make createWorkBranch
  else
    show_heading "Switching to work branches" "for the different repositories and merging main"
    make checkout2work
    for repoDir in $repoDirs
      do
        (
          cd $repoDir
          current_branch="`git rev-parse --abbrev-ref HEAD`"
          if [ "$current_branch" != "work" ]
            then
              git checkout -b work main
            fi
          git merge main
        ) || { show_error "Error merging main into `basename $repoDir`:" "inspect $repoDir and ajdust as necessary" ; exit 1 ; }
      done
  fi


if [ "$REBRANDING_DISABLED" == "true" ]
  then
    show_warning "Not Rebranding:" "ensure that you don't make this available publicly until rebranded, in order to comply with bluesky-social/social-app guidelines"
    echo "https://github.com/bluesky-social/social-app?tab=readme-ov-file#forking-guidelines"
elif [ "$REBRANDING_SCRIPT" == "" ]
  then
    show_error "Rebranding Undefined:" "either define REBRANDING_DISABLED=true or set REBRANDING_SCRIPT in environment, in order to comply with bluesky-social/social-app guidelines"
    echo "https://github.com/bluesky-social/social-app?tab=readme-ov-file#forking-guidelines"
    exit 1
  else
    show_heading "Rebranding social-app" "by scripted changes"
    REBRANDING_SCRIPT_ABS="`realpath "$REBRANDING_SCRIPT"`"
    [ "$REBRANDING_NAME" == "" ] && { show_error "Brand name undefined:" "please set REBRANDING_NAME in $params_file" ; exit 1 ; }
    (
      cd "$script_dir/repos/social-app"
      if [ -n "$(git branch --list local-rebranding-$REBRANDING_NAME)" ]
        then
          show_warning "Overriding social-app branch" "local-rebranding-$REBRANDING_NAME; was at commit `git log --oneline -1 local-rebranding-$REBRANDING_NAME`"
        fi
      git checkout -B local-rebranding-$REBRANDING_NAME work
      "$REBRANDING_SCRIPT_ABS" $REBRANDING_NAME
      git commit -a -m "Automatic rebranding to $REBRANDING_NAME"
    )
  fi

show_heading "Patching each repository" "with changes required for docker build"
# 0) apply mimimum patch to build images, regardless self-hosting.
#      as described in https://github.com/bluesky-social/atproto/discussions/2026 for feed-generator/Dockerfile etc.
# NOTE: this op checks out a new branch before applying patch, and stays on the new branch
make patch-dockerbuild

show_heading "Building social-app" "customized for domain $DOMAIN"
# 1) build social-app image, customized for domain
make build f=./docker-compose-builder.yaml services=social-app

# show_heading "Building other images" "without domain customization"
# 2) build images with original
# make build DOMAIN= f=./docker-compose-builder.yaml 


