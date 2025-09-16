# Unofficial Immich Installer

If you want to install immich natively on linux, visit [arter97's repo](https://github.com/arter97/immich-native) for instructions and scripts to install immich on linux.

### Notes

 * This is tested on macOS Monterey and Sonoma (x86).
   
 * Full Xcode is needed on M-series Macs   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

 * This installer will install Immich to `/opt/services/immich`.

 * The installer currently is using Immich v1.142.1 It should be noted that due to the fast-evolving nature of Immich, the install script may get broken if you replace the `$TAG` to something more recent.

 * `pgvector` is used instead of `pgvecto.rs` that the official Immich uses to remove an additional Rust build dependency.

 * Microservice and machine-learning's host is opened to 0.0.0.0 in the default configuration. This behavior is changed to only accept 127.0.0.1 during installation. Only the main Immich service's port, 3001, is opened to 0.0.0.0.

 * Only the basic CPU configuration is used. Hardware-acceleration such as CUDA is unsupported. In my personal experience, importing about 10K photos on a x86 processor doesn't take an unreasonable amount of time (less than 30 minutes).

 * JPEG XL support may differ official Immich due to base-image's dependency differences.

## 1. Install brew

The installer will install all dependencies as long as brew is installed
See [brew.sh](https://brew.sh) for details about brew

``` bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## 2. Installing

Download the pkg file (from releases) and install it. The installer requires administrator privileges.

The things that the installer does as root:
- create the immich user
- install the LaunchDaemon scripts
- create the immich directories with appropriate permissions
- runs the install script as the immich user

### Building the package from source

run the build.sh script to create a pkg file.

```bash
./build.sh
```

## Done!

Your Immich installation should be running at 3001 port, listening from localhost (127.0.0.1).

Immich will additionally use localhost's 3002 and 3003 ports.

Please add firewall rules and apply https proxy and secure your Immich instance.

## Uninstallation

Uninstallation is now done by executing the uninstall.sh script as root
The script will:
- stop immich from running
- delete the LaunchDaemon scripts
- delete the immich user and group
- delete the database user AND DATABASE
- delete the immich directories

WARNING: running the uninstall script will remove everything that was uploaded to immich

``` bash
sudo sh ./uninstall.sh
```
