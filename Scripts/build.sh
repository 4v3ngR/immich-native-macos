#!/bin/sh

TAG=v1.106.4
IMMICH_PATH=/opt/services/immich
APP=$IMMICH_PATH/app
PASSWD="$1"
BASEDIR="$(dirname "$0")"
PATH=/usr/local/bin:$PATH

if [[ "$USER" != "immich" ]]; then
  rm -rf "$IMMICH_PATH/home" 2> /dev/null
  mkdir -p "$IMMICH_PATH/home"
  chown immich:immich "$IMMICH_PATH/home"

  cp "$0" /tmp/
  s="/tmp/$(basename "$0")"
  chown immich:immich $s
  sudo -u immich "$s" $* 2>&1 || exit 1
  exit
fi

echo "INFO: building immich"

set -euo pipefail

umask 077

rm -rf $APP
mkdir -p $APP

echo 'umask 077' > "$IMMICH_PATH/home/.bashrc"

export HOME="$IMMICH_PATH/home"

echo "INFO: cloning"
TMP="/tmp/immich-$(uuidgen)"
git clone https://github.com/immich-app/immich $TMP
cd $TMP
git reset --hard $TAG

echo "INFO: building the server"
# immich-server
cd server
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
cp -a server/node_modules server/dist server/bin $APP/
cp -a web/build $APP/www
cp -a server/resources server/package.json server/package-lock.json $APP/
cp -a server/start*.sh $APP/
cp -a LICENSE $APP/
cd $APP
npm cache clean --force
cd -

echo "INFO building machine learning"
# immich-machine-learning
mkdir -p $APP/machine-learning
python3 -m venv $APP/machine-learning/venv
(
  # Initiate subshell to setup venv
  . $APP/machine-learning/venv/bin/activate
  pip3 install poetry
  cd machine-learning
  if python -c 'import sys; exit(0) if sys.version_info.major == 3 and sys.version_info.minor > 11 else exit(1)'; then
    echo "Python > 3.11 detected, forcing poetry update"
    # Allow Python 3.12 (e.g., Ubuntu 24.04)
    sed -i -e 's/<3.12/<4/g' pyproject.toml
    poetry update
  fi
  poetry install --no-root --with dev --with cpu

  # downgrade to numpy 1
  pip3 uninstall -y numpy
  pip3 install numpy==1.26.4

  cd ..
)
cp -a machine-learning/ann machine-learning/start.sh machine-learning/app $APP/machine-learning/

echo "INFO: reconfiguring"
# Replace /usr/src
cd $APP
grep -Rl /usr/src | xargs -n1 sed -i -e "s@/usr/src@$IMMICH_PATH@g"
ln -sf $IMMICH_PATH/app/resources $IMMICH_PATH/
mkdir -p $IMMICH_PATH/cache
sed -i -e "s@\"/cache\"@\"$IMMICH_PATH/cache\"@g" $APP/machine-learning/app/config.py

# Install GeoNames
cd $IMMICH_PATH/app/resources
wget -o - https://download.geonames.org/export/dump/admin1CodesASCII.txt &
wget -o - https://download.geonames.org/export/dump/admin2Codes.txt &
wget -o - https://download.geonames.org/export/dump/cities500.zip &
wait
unzip cities500.zip

date -Iseconds | tr -d "\n" > geodata-date.txt

rm cities500.zip

# Install sharp
cd $APP
npm install sharp

# Setup upload directory
mkdir -p $IMMICH_PATH/upload
ln -s $IMMICH_PATH/upload $APP/
ln -s $IMMICH_PATH/upload $APP/machine-learning/

# Use 127.0.0.1
sed -i -e "s@app.listen(port)@app.listen(port, '127.0.0.1')@g" $APP/dist/main.js

# Custom start.sh script
cat <<EOF > $APP/start.sh
#!/bin/bash

export HOME=$IMMICH_PATH/home
export PATH=\$PATH:/usr/local/bin

set -a
. $IMMICH_PATH/env
set +a

cd $APP
exec node $APP/dist/main "\$@"
EOF

cat <<EOF > $APP/machine-learning/start.sh
#!/bin/bash

export HOME=$IMMICH_PATH/home
export PATH=\$PATH:/usr/local/bin

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

# Cleanup
rm -rf $TMP /tmp/$(basename "$0")
