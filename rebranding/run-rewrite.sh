#!/bin/bash

script_path="`realpath "$0"`"
script_dir="`dirname "$script_path"`"
BRAND_CONFIG_DIR="$1"
BRAND_IMAGES_DIR="$2"
cd "$script_dir"
. ../utils.sh

function usage() {
    echo syntax "$0" brand_config_dir brand_images_dir >&2
    echo defined brand config dirs may include: `ls */{social-app,atproto}.yml 2>/dev/null | sed 's#/\(social-app\|atproto\).yml##' | sort -u`
    echo to create a new one, copy opensky-local-com and adjust for your domain name
    echo defined brand images dirs may include: `ls */*-branding.svg 2>/dev/null | sed 's#/.*-branding.svg##' | sort -u`
    echo to create a new one, copy opensky and adjust for your images
}

[[ "$BRAND_CONFIG_DIR" == "" || "$BRAND_IMAGES_DIR" == "" ]] && {
    usage
    exit 1
}

[ -f "$BRAND_CONFIG_DIR"/social-app.yml ] || {
    show_error "Brand config not found" "in directory $BRAND_CONFIG_DIR"
    exit 1
}

BRAND_IMAGES_FILE="`basename "$BRAND_IMAGES_DIR"`-branding.svg" 

[  -f "$BRAND_IMAGES_DIR/$BRAND_IMAGES_FILE" ] || {
    show_error "Brand images not found" "in directory $BRAND_IMAGES_DIR under $BRAND_IMAGES_FILE"
    exit 1
}

BRAND_CONFIG_DIR="`cd "$BRAND_CONFIG_DIR" ; pwd`"
BRAND_IMAGES_DIR="`cd "$BRAND_IMAGES_DIR" ; pwd`"
BRAND_TMP_ENV_FILE="`mktemp --suffix=.env`"
echo "BRAND_CONFIG_DIR=\"${BRAND_CONFIG_DIR}\"" >> "$BRAND_TMP_ENV_FILE" 
echo "BRAND_IMAGES_DIR=\"${BRAND_IMAGES_DIR}\"" >> "$BRAND_TMP_ENV_FILE" 

[ -f bluesky-params.env ] && { set -a ; . $script_dir/bluesky-params.env ; set +a ; }

python $script_dir/export-brand-images.py $BRAND_IMAGES_DIR/$BRAND_IMAGES_FILE || { show_error "Error exporting images" "from $BRAND_IMAGES_DIR" ; exit 1 ; }

[ "$social_app_dir" == "" ] && social_app_dir=../repos/social-app/
[ "$atproto_dir" == "" ] && atproto_dir=../repos/atproto/

(
    [ -f ${BRAND_CONFIG_DIR}/social-app.yml ] || { echo could not find ${BRAND_CONFIG_DIR}/social-app.yml >&2 ; exit 1 ; }

    [ -d "$social_app_dir" ] || { echo could not find social app dir - set '$social_app_dir' in bluesky-rebranding.env or in environment or place at $social_app_dir  >&2 ; exit 1 ; }
    cd "$social_app_dir"
    echo patching social-app in `pwd` with $(basename ${BRAND_CONFIG_DIR})
    git reset --hard
    semgrep scan --config ${BRAND_CONFIG_DIR}/social-app.yml -a || { echo error running semgrep >&2 ; exit 1 ; }
    cp google-services.json.example google-services.json
    python ${script_dir}/apply_files.py --config "$BRAND_CONFIG_DIR"/social-app.yml --env-file "$script_dir"/bluesky-params.env --env-file "$BRAND_TMP_ENV_FILE" || { echo error running apply-files >&2 ; exit 1 ; }
    echo "app_name=${brand}" > branding.env
)

(
    [ -f "${BRAND_CONFIG_DIR}/atproto.yml" ] || { echo could not find ${BRAND_CONFIG_DIR}/atproto.yml >&2 ; exit 1 ; }
    [ -d "$atproto_dir" ] || { echo could not find atproto dir - set '$atproto_dir' in atproto.env or in environment or place at $atproto_dir  >&2 ; exit 1 ; }
    cd "$atproto_dir"
    echo patching atproto in `pwd` with ${brand}
    git reset --hard
    semgrep scan --config "$BRAND_CONFIG_DIR"/atproto.yml -a || { echo error running semgrep >&2 ; exit 1 ; }
)

(
    cd "$social_app_dir"
    # git diff
)
(
    cd "$atproto_dir"
    # git diff
)

