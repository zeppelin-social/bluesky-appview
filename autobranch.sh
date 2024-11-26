#!/bin/bash

# This allows the automated creation of branches, with easier controls over handling common scenarios

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
. "$script_dir/utils.sh"

function usage {
  echo ""
  echo "Usage: $0 [--clobber] target_branch upstream_branch [allowed_starting_branch ...]"
  echo ""
  echo "Switches to target_branch, based on latest upstream_branch"
  echo "Will not do this and exit with an error code if:"
  echo " - there are uncommitted changes"
  echo " - not on target_branch or one of the existing allowed_starting_branches"
  echo ""
  echo "Options:"
  echo " --clobber|-C will overwrite the target_branch rather than merging in changes from upstream_branch, if it exists"
  echo " --delete|-D will delete the target_branch rather than merging in changes from upstream_branch, if it exists"
  echo ""
}

if [[ "$#" -lt 2 ]]
  then
    usage
    exit 1
  fi

do_clobber=
case "$1" in
  -C|--clobber)
    do_clobber=true
    shift
    ;;
  -D|--delete)
    do_delete=true
    shift
    ;;
esac

if [[ "$do_clobber" == "true" && "$do_delete" == "true" ]]
  then
    echo Error in parameters - cannot both clobber and delete >&2
    usage
    exit 1
  fi

target_branch="$1"
upstream_branch="$2"
shift
shift
allowed_starting_branches="$@"
repoDir="`pwd`"
repoName="`basename "$repoDir"`"

git fetch --all
git diff --exit-code --stat || { show_error "Uncommitted changes in $repoName:" "inspect $repoDir and adjust as necessary" ; exit 1 ; }
current_branch="`git rev-parse --abbrev-ref HEAD`"

if [[ "$do_delete" == "true" ]]
  then
    if [[ "$current_branch" == "$target_branch" ]]
      then
        show_error "Cannot delete branch $current_branch" "in $repoName - it's the current checked out branch"
        exit 1
      fi
elif [[ "$current_branch" == "$target_branch" ]]
  then
    echo already on $target_branch branch - merging upstream changes from $upstream_branch
elif [[ "$current_branch" == "`basename $upstream_branch`" ]]
  then
    echo currently on $current_branch branch - switching to $target_branch and merging upstream changes from $upstream_branch
elif [[ "$allowed_starting_branches" != "" ]]
  then
    is_allowed=
    for allowed_starting_branch in $allowed_starting_branches
      do
        if [[ "$current_branch" == "$allowed_starting_branch" ]]
          then
            is_allowed=true
          fi
      done
    if [[ "$is_allowed" != "true" ]]
      then
        show_error "unknown branch $current_branch" "in $repoName is not one of the allowed starting branches [$allowed_starting_branches], aborting autobranch"
        exit 1
      fi
    echo currently on $current_branch branch - switching to $target_branch and merging upstream changes from $upstream_branch
fi

if [ -n "$(git branch --list $target_branch)" ]
  then
    if [[ "$do_clobber" == true ]]
      then
        show_warning "Overwriting $repoName branch $target_branch" "based on $upstream_branch; was at commit `git log --oneline -1 $target_branch`"
        git checkout -B $target_branch $upstream_branch
    elif [[ "$do_delete" == true ]]
      then
        show_warning "Deleting $repoName branch $target_branch" "; was at commit `git log --oneline -1 $target_branch`"
        git branch -D $target_branch
      else
        git checkout $target_branch
        git merge $upstream_branch
    fi
elif [[ "$do_delete" == true ]]
  then
    show_info "Deleting $repoName branch $target_branch" "not done - does not exist"
else
  git checkout -b $target_branch $upstream_branch
fi


