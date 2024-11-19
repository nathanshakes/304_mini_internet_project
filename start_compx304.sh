#!/bin/bash
# This script configures the mini internet project and supporting scripts
# It will automatically suggest packages to install and configuration
# changes to make.
# Generally speaking it is preferable to accept the suggestions of this script

set -e
user_home="/home/$SUDO_USER"
user="$SUDO_USER"
web_root=/var/www/html/

echo_red() {
  tput setaf 1
  echo "$@"
  tput sgr0
}
echo_green() {
  tput setaf 2
  echo "$@"
  tput sgr0
}
echo_yellow() {
  tput setaf 3
  echo "$@"
  tput sgr0
}

estimate_requirements() {

  config_dir="config/"
  if [[ ! -f "$config_dir/AS_config.txt" ]]; then
    echo_red "Cannot find a configuration file named AS_config.txt, cannot calculate system requirements"
    return
  fi

  num_full_ASes=$(grep -c l2_hosts.txt "$config_dir/AS_config.txt") || true
  num_small_ASes=$(grep -c empty.txt "$config_dir/AS_config.txt") || true
  num_IXPs=$(grep -c IXP "$config_dir/AS_config.txt") || true
  num_routers_full=$(wc -l <"$config_dir/l3_routers.txt")
  num_routers_small=$(wc -l <"$config_dir/l3_routers_tier1_and_stub.txt")
  num_switches_full=$(wc -l <"$config_dir/l2_switches.txt")
  num_hosts_full=$(wc -l <"$config_dir/l2_hosts.txt")
  ((num_hosts_full += num_routers_full))
  num_hosts_small="$num_routers_small"
  tot_routers=$((num_full_ASes * num_routers_full + num_small_ASes * num_routers_small))
  tot_switches=$((num_full_ASes * num_switches_full))
  tot_hosts=$((num_full_ASes * num_hosts_full + num_small_ASes * num_hosts_small))
  tot_ssh=$((num_full_ASes + num_small_ASes))

  # 'docker stats' average memory usage for the 2021 containers
  HOST_MEM=10
  SSH_MEM=20
  ROUTER_MEM=40
  SWITCH_MEM=120
  IXP_MEM=40
  # A clean fully configured version of the 2021 config uses 58.1 GB or RAM
  # At the end of teaching the 2021 usage was 77.3 GB - hence a x2 overhead is preferable
  # Measured memory requirements of a clean, fully configured mini-Internet
  # 12 AS=5.9GB, 20 AS=14.7GB, 30 AS=21.1GB, 72 AS=58.1GB
  # This function calculates
  # 12 AS=5/9GB, 20 AS=15/25GB, 30 AS=23/38GB, 72 AS=59/98GB (min/recommended)

  _required_mem=$((HOST_MEM * tot_hosts + ROUTER_MEM * tot_routers + SWITCH_MEM * tot_switches + IXP_MEM * num_IXPs + SSH_MEM * tot_ssh))

  # Scale by 1.2 (+600M system) to account for other overheads, not counted by 'docker stats'
  # This is the amount of resident memory required by a clean mini-internet install with nothing else running
  required_mem=$((_required_mem * 6 / 5 + 600))
  # Double it to allow a decent overhead for student access, growth with use over time, file caches etc.
  recommended_mem=$((_required_mem * 2 + 600))
  echo "The mini-Internet is configured to create:"
  echo " $((num_full_ASes + num_small_ASes)) ASes"
  echo "   Light:$num_small_ASes Full:$num_full_ASes +IXPs:$num_IXPs"
  echo " $((tot_routers + tot_switches + tot_hosts + tot_ssh + num_IXPs + 3)) docker containers"
  echo "    Hosts:$tot_hosts Routers:$tot_routers Switches:$tot_switches IXPs:$num_IXPs SSH hosts:$tot_ssh Other:3"
  num_CPU=$(getconf _NPROCESSORS_ONLN)
  CPU_recommended=$(((tot_routers + num_IXPs) / 37 + 1))
  echo
  echo -n "Number of CPU cores recommended: $CPU_recommended   found: "
  if [[ $num_CPU -lt $CPU_recommended ]]; then
    echo_red "$num_CPU"
  else
    echo_green "$num_CPU"
  fi

  echo "Running the mini-Internet platform alone is expected to use $((required_mem / 1024))GB of RAM"
  echo "You should allow at least $((recommended_mem / 1024))GB of RAM for a long-running teaching deployment"
  echo -n "Memory min: $((required_mem / 1024))GB  recommended: $((recommended_mem / 1024))GB   found: "

  # Warn if installed memory is low
  mem_size_MB=$(free -m | awk '/^Mem:/{print $2}')
  if [[ $mem_size_MB -lt $recommended_mem ]]; then
    if [[ $mem_size_MB -lt $required_mem ]]; then
      echo_red $((mem_size_MB / 1024))GB
      echo_red "WARNING: You most likely don't have enough RAM to start this configuration"
    else
      echo_yellow $((mem_size_MB / 1024))GB
      echo_yellow "You have less RAM installed than is recommended for a long-running teaching deployment"
    fi
    read -r -p "Would you like to continue anyway? [y/N]"
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Exiting"
      exit 1
    fi
  else
    echo_green $((mem_size_MB / 1024))GB
  fi
}

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

# Check if unattended-upgrades is installed and if so, uninstall it
if command -v unattended-upgrade >/dev/null 2>&1; then
  echo "Found unattended upgrades installed, this may cause problems with the mini-Internet"
  echo "If a unattended upgrade restarts key components such as docker or OvS this may break the mini-Internet"
  read -r -p "Would you like to remove unattended upgrades? [y/N]"
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt-get purge -y unattended-upgrades
  else
    echo "Continuing with unattended upgrades installed"
  fi
fi

SYSCTL_LIMITS='# the mini-Internet hits Inotify file watch limits and systemctl complains
fs.inotify.max_user_instances = 524288
fs.inotify.max_user_watches = 524288
fs.inotify.max_queued_events = 163840

# Neighbour cache also fills up
net.ipv4.neigh.default.gc_thresh1 = 16384
net.ipv4.neigh.default.gc_thresh2 = 32768
net.ipv4.neigh.default.gc_thresh3 = 65536'

if [[ ! -f /etc/sysctl.d/60-mini-internet.conf ]]; then
  echo "sysctl default file inotify and ipv4 neighbour cache limits found"
  echo "A class-sized mini-Internet exceeds the default limits"
  echo "The recommended limits are:"
  echo "$SYSCTL_LIMITS"
  echo
  read -r -p "Would you like install higher limits to /etc/sysctl.d/60-mini-internet.conf and apply them? [y/N]" -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "$SYSCTL_LIMITS" >/etc/sysctl.d/60-mini-internet.conf
    sysctl --load=/etc/sysctl.d/60-mini-internet.conf
  else
    echo "Continuing with default limits"
  fi
fi

if ! command -v docker &>/dev/null; then
  echo "Docker is not installed."
  read -r -p "Would you like to automatically install Docker? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing any conflicting Docker packages..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
      sudo apt-get remove -y $pkg || true
    done

    echo "Updating package index and installing dependencies..."
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg

    echo "Setting up Docker's official GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod 644 /etc/apt/keyrings/docker.asc

    echo "Adding Docker repository to Apt sources..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "Updating package index again..."
    sudo apt-get update -y

    echo "Installing Docker packages..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Docker installation completed successfully."
  else
    echo "Docker installation aborted."
    exit 1
  fi
fi

# check if OvS is installed
if ! command -v ovs-vsctl &>/dev/null; then
  echo "Open vSwitch not installed"
  read -r -p "Would you like to automatically install openvswitch-switch? [y/N]" -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y openvswitch-switch
  else
    exit 1
  fi
fi

# check if OpenVPN is installed
if ! command -v openvpn &>/dev/null; then
  echo "OpenVPN not installed"
  read -r -p "Would you like to automatically install OpenVPN? [y/N]" -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install -y openvpn
  else
    exit 1
  fi
fi

# Get the current kernel version
KERNEL_VERSION=$(uname -r)

# Check if the package is installed
if ! dpkg -l | grep -q "linux-modules-extra-$KERNEL_VERSION"; then
  echo "The package 'linux-modules-extra-$KERNEL_VERSION' is not installed."
  read -r -p "Would you like to install it? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Updating package index..."
    sudo apt update -y

    echo "Installing 'linux-modules-extra-$KERNEL_VERSION'..."
    sudo apt install -y linux-modules-extra-"$KERNEL_VERSION"

    echo "'linux-modules-extra-$KERNEL_VERSION' installation completed successfully."
  else
    echo "Installation aborted. Some kernel modules may not be available."
    exit 1
  fi
fi


# Check if logrotate is installed, if so, suggest rotating docker logs
if command -v logrotate &>/dev/null && [[ ! -f /etc/logrotate.d/docker ]]; then
  echo "While the mini-Internet project doesn't use much disk. Docker logs will after an extended period."
  read -r -p "Would you like to install a logrotate rule to rotate docker logs daily (retaining 5)? [y/N]"
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "$DOCKER_LOGROTATE" >/etc/logrotate.d/docker
    echo "/etc/logrotate.d/docker installed successfully"
  fi
fi

exec > >(tee -ia startup.log)
exec 2> >(tee -ia startup.log >&2)

# args: date, time etc.
type_to_screen() {
  screen -XS "$1" stuff "$2"
}


cd ./platform

estimate_requirements
echo "A large class-sized mini-Internet can take in the order of hours to start"
read -r -p "Would you like to continue with the configuration above and start the mini-Internet? [y/N]"
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Exiting"
  exit 1
fi

#Build Docker Images
./docker_images/304_docker_build.sh

# Start mini-internet
./startup.sh

echo_green "The mini-Internet project is now running"
echo

echo_red "You should now verify that the mini-Internet is running correctly."
echo " - Check how many resources RAM/CPU etc. the mini-Internet is using"
echo " - Copy external_links_config_students.txt to as_connections.txt on the webserver"
echo " - Check the webserver is configured correctly with HTTPS and access rules"
echo " - Verify the website is working and that the matrix is green for configured ASes"
echo " - Verify ssh is working for the groups and measurement container"
echo " - Implement offsite backups of the backup directory $(realpath ../backups)"
echo " - Run through labs and assignments to check they work correctly"
