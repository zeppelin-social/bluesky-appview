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

show_heading "Auto-creating latest work branch" "from the different repositories"
for repoDir in $repoDirs
  do
    (
      cd $repoDir
      echo "$blue_color$clear_bold`basename ${repoDir}`$reset_color"
      $script_dir/autobranch.sh work origin/main dockerbuild local-rebranding-$REBRANDING_NAME
    ) || { show_error "Error updating to latest branch:" "inspect $repoDir and adjust as necessary" ; exit 1 ; }
  done


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
      $script_dir/autobranch.sh -C local-rebranding-$REBRANDING_NAME work dockerbuild
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


