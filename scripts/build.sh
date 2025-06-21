#!/usr/bin/env bash

clone_or_pull() {
    if [ -d "repos/$1" ]; then
        echo "Pulling $1"
        cd "repos/$1" || exit
        git pull
        cd - || exit
    else
        echo "Cloning $1"
        git clone "https://github.com/zeppelin-social/$1.git" "repos/$1"
    fi
}

IFS=" " read -r -a services <<< "$(yq '.services | keys | join(" ")' docker-compose.yaml | sed 's/"//g')"

args=("$@")
to_build=()
if [[ ${#args[@]} -eq 0 ]]; then
    to_build=("${services[@]}")
else
    for arg in "${args[@]}"; do
        if [[ ! ${services[*]} =~ (^|[[:space:]])${arg}($|[[:space:]]) ]]; then
            echo "Unknown service: $arg"
            exit 1
        else
            to_build+=("$arg")
        fi
    done
fi

for service in "${to_build[@]}"; do
    if [[ $(yq '.services."'"$service"'".build.context' docker-compose.yaml) != null ]]; then
        repo_name=$(yq '.services."'"$service"'".build.context' docker-compose.yaml | sed 's/.*\/\(.*\)\/.*/\1/')
        clone_or_pull "$repo_name"
    fi
done

COMPOSE_BAKE=true docker compose build "${to_build[@]}"
