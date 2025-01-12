#!/usr/bin/env bash

TMP_DIR=/tmp/nginxproxymanager
PREFIX=${PREFIX:-"/usr/local"}
DISABLE_IPV6=${DISABLE_IPV6:-true}

# Create a temporary directory to store the files
rm -rf $TMP_DIR
mkdir -p $TMP_DIR
cd $TMP_DIR

process_folder () {
    FILES=$(find "$1" -type f -name "*.conf")
    SED_REGEX=

    if [ "$DISABLE_IPV6" == "true" ] || [ "$DISABLE_IPV6" == "on" ] || [ "$DISABLE_IPV6" == "1" ] || [ "$DISABLE_IPV6" == "yes" ]; then
        # IPV6 is disabled
        echo "Disabling IPV6 in hosts in: $1"
        SED_REGEX='s/^([^#]*)listen \[::\]/\1#listen [::]/g'
    # else
    #     # IPV6 is enabled
    #     echo "Enabling IPV6 in hosts in: $1"
    #     SED_REGEX='s/^(s*)#listen \[::\]/\1listen [::]/g'
    fi

    for FILE in $FILES; do
        echo "- ${FILE}"
        echo "$(sed -E "$SED_REGEX" "$FILE")" > $FILE
    done
}

# Update the package repository to ensure we have the latest information
pkg update -f

# Upgrade all installed packages to their latest versions
pkg upgrade -y

# Remove specific packages: nginx-full, py311-certbot, and py311-certbot-nginx
pkg remove -y nginx-full py311-certbot py311-certbot-nginx

# Remove specific directories and files related to npm, nginx, and letsencrypt
rm -rf $PREFIX/share/npm \
    $PREFIX/www/html \
    $PREFIX/etc/nginx \
    $PREFIX/etc/letsencrypt.ini \
    $PREFIX/etc/logrotate.d/nginx-proxy-manager \
    $PREFIX/etc/nginx/conf/nginx.conf \
    $PREFIX/etc/nginx/conf.d/include/resolvers.conf \
    $PREFIX/etc/nginx/conf.d/include/ssl.conf

# Install specific packages: nginx-full, py311-certbot, py311-certbot-nginx, node18, npm-node18, and py-htpasswd
pkg install -y www/nginx-full \
    py311-certbot py311-certbot-nginx \
    www/node18 \
    www/npm-node18 \
    security/py-htpasswd \
    logrotate \
    git-lite \
    curl logrotate \
    git-lite

# install yarn
npm install -g yarn

# install certbot
# pkg install -y py311-virtualenv
# mkdir -p $PREFIX/opt/certbot
# python -m venv $PREFIX/opt/certbot
# . $PREFIX/opt/certbot
# pip install -q -U --no-cache-dir cryptography cffi certbot tldextract

# get npm files from repository
NPM_VERSION=$(curl -L https://api.github.com/repos/icaksh/freebsd-nginx-proxy-manager/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -L https://codeload.github.com/icaksh/freebsd-nginx-proxy-manager/tar.gz/v$NPM_VERSION | tar -xz
# git clone -b develop --single-branch https://github.com/icaksh/freebsd-nginx-proxy-manager.git $TMP_DIR/freebsd-nginx-proxy-manager-$NPM_VERSION
TMP_DIR=/tmp/nginxproxymanager/freebsd-nginx-proxy-manager-$NPM_VERSION
cd $TMP_DIR

# env settings
# update the version in backend and frontend package.json files
sed -i "" "s/\"version\": \"0.0.0\"/\"version\": \"$NPM_VERSION\"/" $TMP_DIR/backend/package.json
sed -i "" "s/\"version\": \"0.0.0\"/\"version\": \"$NPM_VERSION\"/" $TMP_DIR/frontend/package.json

# modify nginx configuration for user and pid settings
sed -i "" 's/user npm/user root wheel/g; s/^pid/#pid/g; s+^daemon+#daemon+g' $TMP_DIR/base/rootfs/etc/nginx/nginx.conf

# update include paths in nginx configuration files
nginxConfigs=$(find ./ -type f -name "*.conf")
for nginxConfig in $nginxConfigs; do
    sed -i "" 's+include conf.d+include '$PREFIX'/etc/nginx/conf.d+g' "$nginxConfig"
done

# Copy runtime files
mkdir $PREFIX/www/html $PREFIX/etc/nginx/logs $PREFIX/etc/nginx/conf
cp -r $TMP_DIR/base/rootfs/www/html/* $PREFIX/www/html/
cp -r $TMP_DIR/base/rootfs/etc/nginx/* $PREFIX/etc/nginx/
cp $TMP_DIR/base/rootfs/etc/letsencrypt.ini $PREFIX/etc/letsencrypt.ini
cp $TMP_DIR/base/rootfs/etc/logrotate.d/nginx-proxy-manager $PREFIX/etc/logrotate.d/nginx-proxy-manager
ln -sf $PREFIX/etc/nginx/nginx.conf $PREFIX/etc/nginx/conf/nginx.conf
rm -f $PREFIX/etc/nginx/conf.d/dev.conf

# Create required folders
mkdir -p \
	$PREFIX/share/nginxproxymanager/nginx \
	$PREFIX/share/nginxproxymanager/custom_ssl \
	$PREFIX/share/nginxproxymanager/logs \
	$PREFIX/share/nginxproxymanager/access \
	$PREFIX/share/nginxproxymanager/nginx/default_host \
	$PREFIX/share/nginxproxymanager/nginx/default_www \
	$PREFIX/share/nginxproxymanager/nginx/proxy_host \
	$PREFIX/share/nginxproxymanager/nginx/redirection_host \
	$PREFIX/share/nginxproxymanager/nginx/stream \
	$PREFIX/share/nginxproxymanager/nginx/dead_host \
	$PREFIX/share/nginxproxymanager/nginx/temp \
	$PREFIX/share/nginxproxymanager/letsencrypt-acme-challenge \
	$PREFIX/share/nginxproxymanager/run/nginx \
	/tmp/nginx/body \
	/var/log/nginx \
	/var/lib/nginx/cache/public \
	/var/lib/nginx/cache/private \
	/var/cache/nginx/proxy_temp \
    $PREFIX/etc/lograte.d/nginx-proxy-manager

# Set permissions
touch /var/log/nginx/error.log
chmod 777 /var/log/nginx/error.log
chmod -R 777 /var/cache/nginx
chmod 644 $PREFIX/etc/logrotate.d/nginx-proxy-manager
chown root /tmp/nginx
chmod -R 777 /var/cache/nginx


# ipv6 config
if [ "$DISABLE_IPV6" == "true" ] || [ "$DISABLE_IPV6" == "on" ] || [ "$DISABLE_IPV6" == "1" ] || [ "$DISABLE_IPV6" == "yes" ];
then
	echo resolver "$(awk 'BEGIN{ORS=" "} $1=="nameserver" { sub(/%.*$/,"",$2); print ($2 ~ ":")? "["$2"]": $2}' /etc/resolv.conf) ipv6=off valid=10s;" > $PREFIX/etc/nginx/conf.d/include/resolvers.conf
else
	echo resolver "$(awk 'BEGIN{ORS=" "} $1=="nameserver" { sub(/%.*$/,"",$2); print ($2 ~ ":")? "["$2"]": $2}' /etc/resolv.conf) valid=10s;" > $PREFIX/etc/nginx/conf.d/include/resolvers.conf
fi

process_folder $PREFIX/etc/nginx/conf.d
process_folder $PREFIX/share/nginxproxymanager/nginx

# building frontend
cd $TMP_DIR/frontend
export NODE_ENV=development
export NODE_OPTIONS=--openssl-legacy-provider 
yarn cache clean --silent --force
yarn install --silent --network-timeout=30000
yarn build

# copy backend
cd ..
cp -r $TMP_DIR/backend/* $PREFIX/etc/nginxproxymanager/
cp -r $TMP_DIR/global/* $PREFIX/etc/nginxproxymanager/global

# Copy app files
mkdir -p $PREFIX/etc/nginxproxymanager/global $PREFIX/etc/nginxproxymanager/frontend/images
cp -r $TMP_DIR/frontend/dist/* $PREFIX/etc/nginxproxymanager/frontend/
cp -r $TMP_DIR/frontend/app-images/* $PREFIX/etc/nginxproxymanager/frontend/images/

# initializing
rm -rf $PREFIX/etc/nginxproxymanager/config/default.json
if [ ! -f $PREFIX/etc/nginxproxymanager/config/production.json ]; then
    _npmConfig="{\n  \"database\": {\n    \"engine\": \"knex-native\",\n    \"knex\": {\n      \"client\": \"sqlite3\",\n      \"connection\": {\n        \"filename\": \"$PREFIX/share/nginxproxymanager/usr/local/share/nginxproxymanager/base.sqlite\"\n      }\n    }\n  }\n}"
    printf "$_npmConfig\n" | tee $PREFIX/etc/nginxproxymanager/config/production.json
fi
cd $PREFIX/etc/nginxproxymanager
export NODE_ENV=production
yarn install --silent --network-timeout=30000

# cleanup
yarn cache clean --silent --force

# starting nginx service
service nginx enable
service nginx start

# starting npm service
mkdir -p /usrlocal/etc/rc.d
cp $TMP_DIR/base/rootfs/etc/rc.d/nginxproxymanager /usr/local/etc/rc.d/nginxproxymanager
chmod +x /usr/local/etc/rc.d/nginxproxymanager
service nginxproxymanager enable
service nginxproxymanager start