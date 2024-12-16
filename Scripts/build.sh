#!/bin/sh

. ./config.sh || exit 1

if [ -z "$TAG" ]; then
  echo "DEBUG: config not working"
  exit 1
fi

PASSWD="$1"

if [[ "$USER" != "immich" ]]; then
  echo "DEBUG: going to switch to immich user"
  rm -rf "$IMMICH_PATH/home" 2> /dev/null
  mkdir -p "$IMMICH_PATH/home"
  chown immich:immich "$IMMICH_PATH/home"

  # move to a place were immich has permission
  cwd=$(dirname "$0")
  echo "DEBUG: copying scripts to accessible location"
  cp "$0" "config.sh" /tmp/

  s="/tmp/$(basename "$0")"
  chown immich:immich $s
  sudo -u immich "$s" $* 2>&1 || exit 1
  exit
fi

echo "INFO: building immich"

export HOME="$IMMICH_PATH/home"

set -euo pipefail
umask 077

echo 'umask 077' > "$HOME/.bashrc"

echo "INFO: cloning immich repo"
TMP="/tmp/immich-$(uuidgen)"
git clone https://github.com/immich-app/immich $TMP
cd $TMP
git reset --hard $TAG

echo "INFO: building the server"
cd server
export SHARP_FORCE_GLOBAL_LIBVIPS="yes"
npm install --save node-addon-api node-gyp
npm ci
npm run build
npm prune --omit=dev --omit=optional
cd -

echo "INFO: building open-api"
cd open-api/typescript-sdk
npm ci
npm run build
cd -

echo "INFO: building web"
cd web
npm ci
npm run build
cd -

echo "INFO: copying to destination directory"
rm -rf $APP
mkdir -p $APP

cp -a server/node_modules server/dist server/bin $APP/
cp -a web/build $APP/www
cp -a server/resources server/package.json server/package-lock.json $APP/
cp -a server/start*.sh $APP/
cp -a LICENSE $APP/

cd $APP
# v1.108.0 and above now loads geodata using IMMICH_BUILD_DATA env var, which appears to also
# be used in other places
ln -sf resources/* .
npm cache clean --force
npm install --os=darwin --cpu=x64 sharp
cd -

echo "INFO building machine learning"
# force use of python3.11
alias python3=python3.11
alias pip3=pip3.11

mkdir -p $APP/machine-learning
python3 -m venv $APP/machine-learning/venv
(
  # Initiate subshell to setup venv
  . $APP/machine-learning/venv/bin/activate
  pip3 install poetry
  cd machine-learning
  poetry install --no-root --with dev --with cpu || python3 -m pip install onnxruntime
  cd ..
)
cp -a machine-learning/ann machine-learning/app $APP/machine-learning/

ln -sf $IMMICH_PATH/app/resources $IMMICH_PATH/
mkdir -p $IMMICH_PATH/cache
sed -i "" -e "s@\"/cache\"@\"$IMMICH_PATH/cache\"@g" $APP/machine-learning/app/config.py
npm install sharp

# Install GeoNames
cd $IMMICH_PATH/app/resources
wget -o - https://download.geonames.org/export/dump/admin1CodesASCII.txt &
wget -o - https://download.geonames.org/export/dump/admin2Codes.txt &
wget -o - https://download.geonames.org/export/dump/cities500.zip &
wget -o - https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_admin_0_countries.geojson &
wait
unzip cities500.zip

date -Iseconds | tr -d "\n" > geodata-date.txt

rm cities500.zip
ln -s $IMMICH_PATH/app/resources $IMMICH_PATH/app/geodata

# Setup upload directory
mkdir -p $IMMICH_PATH/upload
ln -s $IMMICH_PATH/upload $APP/
ln -s $IMMICH_PATH/upload $APP/machine-learning/

# Custom start.sh script
cat <<EOF > $APP/start.sh
#!/bin/bash

export IMMICH_PORT=3001
export HOME=$IMMICH_PATH/home
export PATH=\$PATH:/usr/local/bin:/opt/homebrew/bin

set -a
. $IMMICH_PATH/env
set +a

cd $APP
exec node $APP/dist/main "\$@"
EOF

cat <<EOF > $APP/machine-learning/start.sh
#!/bin/bash

export HOME=$IMMICH_PATH/home
export PATH=\$PATH:/usr/local/bin:/opt/homebrew/bin

set -a
. $IMMICH_PATH/env
set +a

cd $APP/machine-learning
. venv/bin/activate

: "\${MACHINE_LEARNING_HOST:=127.0.0.1}"
: "\${MACHINE_LEARNING_PORT:=3003}"
: "\${MACHINE_LEARNING_WORKERS:=1}"
: "\${MACHINE_LEARNING_WORKER_TIMEOUT:=120}"

exec gunicorn app.main:app \
      -k app.config.CustomUvicornWorker \
      -w "\$MACHINE_LEARNING_WORKERS" \
      -b "\$MACHINE_LEARNING_HOST":"\$MACHINE_LEARNING_PORT" \
      -t "\$MACHINE_LEARNING_WORKER_TIMEOUT" \
      --log-config-json log_conf.json \
      --graceful-timeout 0
EOF

cat <<EOF > $IMMICH_PATH/env
# You can find documentation for all the supported env variables at https://immich.app/docs/install/environment-variables

# Connection secret for postgres. You should change it to a random password
DB_PASSWORD=$PASSWD

# The values below this line do not need to be changed
###################################################################################
NODE_ENV=production

DB_USERNAME=immich
DB_DATABASE_NAME=immich
DB_VECTOR_EXTENSION=pgvector

IMMICH_BUILD_DATA=$IMMICH_PATH/app

# The location where your uploaded files are stored
UPLOAD_LOCATION=./library

# The Immich version to use. You can pin this to a specific version like "v1.71.0"
IMMICH_VERSION=release

# Hosts & ports
DB_HOSTNAME=127.0.0.1
MACHINE_LEARNING_HOST=127.0.0.1
IMMICH_MACHINE_LEARNING_URL=http://127.0.0.1:3003
REDIS_HOSTNAME=127.0.0.1
EOF

chmod 700 $APP/start.sh
chmod 700 $APP/machine-learning/start.sh

# Cleanup
rm -rf $TMP /tmp/$(basename "$0")
