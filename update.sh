#!/bin/bash
set -e

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
)

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

#current="$(curl -fsSL 'https://packagist.org/p/yourls/yourls.json' | jq -r '?')"
current="$(curl -fsSL 'https://api.github.com/repos/YOURLS/YOURLS/releases' | jq -r '.[0].tag_name')"

travisEnv=
for variant in apache fpm; do
    mkdir -p "$current/$variant"

    cp Dockerfile.template "$current/$variant/Dockerfile"

    sed -ri \
        -e 's/%%VARIANT%%/'"$variant"'/' \
        -e 's/%%VERSION%%/'"$current"'/' \
        -e 's/%%CMD%%/'"${cmd[$variant]}"'/' \
        "$current/$variant/Dockerfile"

    if [ "$variant" = 'fpm' ]; then
        sed -ri -e '/a2enmod/d' "$current/$variant/Dockerfile"
    fi

    cp -a docker-entrypoint.sh "$current/$variant/docker-entrypoint.sh"
    cp -a config-docker.php "$current/$variant/config-docker.php"

    travisEnv='\n  - VERSION='"$current"' VARIANT='"$variant$travisEnv"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
