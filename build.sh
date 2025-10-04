. ./Scripts/config.sh

if [ -z "$TAG" ]; then
  echo "DEBUG: config not working"
  exit 1
fi

mkdir -p dist/$TAG
pkgbuild --version $TAG --root LaunchDaemons --identifier com.unofficial.immich.installer --scripts Scripts --install-location /Library/LaunchDaemons dist/$TAG/Unofficial\ Immich\ Installer-$TAG.pkg

# need to increase script timeouts
cd "dist/$TAG"
pkgutil --expand Unofficial\ Immich\ Installer-$TAG.pkg contents
sed -i ".bak" -e 's/600/3600/g' contents/PackageInfo
rm -f contents/Bom contents/*.bak
mkbom contents contents/Bom
pkgutil --flatten contents Unofficial\ Immich\ Installer-$TAG.pkg
rm -rf contents
cd -
