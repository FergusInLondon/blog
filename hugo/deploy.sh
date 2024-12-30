if [[ $CF_PAGES_BRANCH = "master" ]]; then
    PARAMS=""
else 
    PARAMS="-b $CF_PAGES_URL"
fi

hugo --gc --minify $PARAMS
