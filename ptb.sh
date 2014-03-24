#!/usr/bin/env bash

# Copyright (C) PetaByet.com All Rights Reserved

pname="{$1}"
price="${2}"
provider="${3}"
token="${4}"

# Working directory.
CWD="$(pwd)"

PKGS_TO_INSTALL=('curl' 'gcc' 'make' 'wget')

BENCHMARK_DIR='petabyet'
IOPING=""
IOPING_VERSION='0.8'

function die() {
    echo "ERROR: "${@}
    exit
}

function welcome_banner() {
    clear
    echo
    echo "
    #############################################################
    # PetaByet.com :: All-in-one server performance test script #
    #############################################################
    "
    sleep 1
    echo "Welcome!"
    echo "Please make sure that your server"
    echo "is running a fresh OS Installation"
    echo
    echo "The benchmark will start in 10 seconds, quit IMMEDIATELY if you don't want to proceed"
    echo
    echo "WARNING: Run this script at your own risk."
    echo "This script may install additional software packages."

    echo -ne "###                                               (10s)\r"
    sleep 1
    echo -ne "######                                             (9s)\r"
    sleep 1
    echo -ne "#########                                          (8s)\r"
    sleep 1
    echo -ne "############                                       (7s)\r"
    sleep 1
    echo -ne "###############                                    (6s)\r"
    sleep 1
    echo -ne "##################                                 (5s)\r"
    sleep 1
    echo -ne "#####################                              (4s)\r"
    sleep 1
    echo -ne "########################                           (3s)\r"
    sleep 1
    echo -ne "###########################                        (2s)\r"
    sleep 1
    echo -ne "##############################                     (1s)\r"
    sleep 1
    echo -ne "#################################                  (0s)\r"
    echo -ne "\n"
    clear
    echo " "
}

function cmd_exists() {
    hash ${1} 2>/dev/null
    return $?
}

function pkg_exists() {
    ${PKG_CHECK} ${1} 2>/dev/null >/dev/null
    return $?
}

function setup_package_manager() {
    if cmd_exists 'apt-get'; then
        DISTRO='ubuntu/debian'
        PKG_CHECK='dpkg -s'
        PKG_UPDATE='apt-get update'
        PKG_INSTALL='apt-get install --assume-yes'
    elif cmd_exists 'yum'; then
        DISTRO='centos/fedora'
        PKG_CHECK='rpm -q'
        PKG_UPDATE='yum clean all'
        PKG_INSTALL='yum install -y'
    elif cmd_exists 'zypper'; then
        DISTRO='opensuse'
        PKG_CHECK='rpm -q'
        PKG_UPDATE='zypper refresh'
        PKG_INSTALL='zypper --non-interactive install --no-recommends'
    elif cmd_exists 'pacman'; then
        DISTRO='archlinux'
        PKG_CHECK='pacman -Q'
        PKG_UPDATE='pacman -Syy'
        PKG_INSTALL='pacman -S --needed --noconfirm'
    else
        die "OS/Package manager not supported; exiting."
    fi
}

function check_required_packages() {
    setup_package_manager
    missing_packages=""
    for p in ${PKGS_TO_INSTALL[@]}; do
        if ! pkg_exists ${p}; then
            missing_packages=${missing_packages}" "${p}
        fi
    done

    if [ -n "${missing_packages}" ]; then
        if [ $(id -u) -eq 0 ]; then
            echo "The following packages are missing, but we are going to try to install them:"${missing_packages}
            sleep 1
            ${PKG_UPDATE} || die "Problem trying to update packages database."
            ${PKG_INSTALL} ${missing_packages} || die "Problem during the packages install; please install the missing packages with '"${PKG_INSTALL}${missing_packages}"'."
        else
            die "The following packages are missing:"${missing_packages}". You can try to install them with '"${PKG_INSTALL}${missing_packages}"'."
        fi
    fi
}

function check_ioping_version() {
    if [[ "$(${IOPING} -v 2>&1)" != "ioping "${IOPING_VERSION} ]]; then
        die "IOPing is not the expected version."
    fi
}

function setup_ioping() {
    if cmd_exists 'ioping'; then
        IOPING=$(which ioping)
    elif [[ -x "${CWD}"/${BENCHMARK_DIR}/ioping-${IOPING_VERSION}/ioping ]]; then
        IOPING="${CWD}"/${BENCHMARK_DIR}/ioping-${IOPING_VERSION}/ioping
        check_ioping_version
    else
        echo "IOPing not found; installing..."

        rm -rf ioping-${IOPING_VERSION}*
        wget --prefer-family=IPv4 https://ioping.googlecode.com/files/ioping-${IOPING_VERSION}.tar.gz || die "Problem downloading IOPing; please try again."
        tar xf ioping-${IOPING_VERSION}.tar.gz || die "Problem during untar of IOPing; please try again."
        pushd ioping-${IOPING_VERSION} >/dev/null
        make || die "Problem during build of ioping; please try again."
        export PATH="$(pwd)":"${PATH}"
        IOPING=$(which ioping)
        popd >/dev/null
        check_ioping_version
    fi

    # Make sure IOPing is correctly set.
    if [[ ! -x ${IOPING} ]]; then
        die "IOPing ("${IOPING}") does not exist or is not an executable."
    fi
}


function network_test() {
    url=${1}
    wget --prefer-family=IPv4 -O /dev/null ${url} 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' || die "Problem trying to download the test file from "${url}"."
}


function run_network_tests() {
    echo
    echo "========== Speed test ========="
    echo
    echo "Downloading from SoftLayer, Dallas, USA"
    geo37=$(network_test http://speedtest.dal01.softlayer.com/downloads/test100.zip)
    echo "Downloading from ReliableSite, Piscataway, USA"
    geo40=$(network_test http://speedtest.choopa.net/100MBtest.bin)
    echo "Downloading from OVH, Beauharnois, Canada"
    geo11=$(network_test http://bhs.proof.ovh.net/files/100Mio.dat)
    echo "Downloading from Softlayer, Washington, USA"
    geo22=$(network_test http://speedtest.wdc01.softlayer.com/downloads/test100.zip)
    echo "Downloading from SoftLayer, San Jose, USA"
    geo3=$(network_test http://speedtest.sjc01.softlayer.com/downloads/test100.zip)
    echo
    echo
    echo "Downloading from ThinkBroadband, London, United Kingdom"
    geo20=$(network_test http://ipv4.download.thinkbroadband.com/100MB.zip)
    echo "Downloading from Tele2, Stockholm, Sweden"
    geo24=$(network_test http://speedtest.tele2.net/100MB.zip)
    echo "Downloading from OVH, Roubaix, France"
    geo10=$(network_test http://rbx.proof.ovh.net/files/100Mio.dat)
    echo "Downloading from Prometeus, Milan, Italy"
    geo41=$(network_test http://mirrors.prometeus.net/test/test100.bin)
    echo "Downloading from LeaseWeb, Frankfurt, Germany"
    geo9=$(network_test http://mirror.de.leaseweb.net/speedtest/100mb.bin)
    echo "Downloading from Interactive3D, Amsterdam, Netherlands"
    geo6=$(network_test http://mirror.i3d.net/100mb.bin)
    echo
    echo
    echo "Downloading from SoftLayer, Singapore, Singapore"
    geo26=$(network_test http://speedtest.sng01.softlayer.com/downloads/test100.zip)
    echo "Downloading from Linode, Tokyo, Japan"
    geo12=$(network_test http://speedtest.tokyo.linode.com/100MB-tokyo.bin)
    echo
    echo
    echo "Downloading from RansomIT, Sydney, Australia"
    geo25=$(network_test http://www.ransomit.com.au/100MB)
    echo
    echo
    echo "Downloading from CacheFly CDN Network"
    geo1=$(network_test http://cachefly.cachefly.net/100mb.test)
    echo "Downloading from Internode CDN Network"
    geo33=$(network_test http://speedcheck.cdn.on.net/100meg.test)
    echo
}

function server_specs() {
    echo
    echo "========== Server Specs =========";
    echo
    echo "Getting CPU information..."
    cname=$(awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo)
    sleep 1
    cmhz=$(awk -F: '/cpu MHz/ {name=$2} END {print name}' /proc/cpuinfo)
    echo "Getting CPU Cores information..."
    cores=$(awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo)
    sleep 1
    echo "Getting RAM information..."
    tram=$(free -m | awk 'NR==2 {print $2}')
    sleep 1
    echo "Getting Swap RAM information..."
    swap=$(free -m | awk 'NR==4 {print $2}')
    sleep 1
    echo "Getting disk space information..."

    # Old versions of df dont handle --total, so in such case we calculate it manually.
    dftotal=$(df --total 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        disk=$(echo "${dftotal}" | tail -1 | awk '{print $2}')
    else
        disk=$(df | tail -n +2 | awk '{total+=$2} END {print total}')
    fi
}

function run_io_tests() {
    echo
    echo "========== I/O =========";
    echo
    echo "Testing I/O Speed (dd)"
    dd=$((dd if=/dev/zero of=test_$$ bs=64k count=16k conv=fdatasync && rm -f test_$$) 2>&1 | awk -F, '{io=$NF} END { print io}')
    echo "Testing IOPing"
    ioping=$(${IOPING} -c 10 -L . | grep -E '(mdev)')
    echo "Testing Seek"
    seek=$(${IOPING} -R . | grep -E '(iops|mdev)')
    echo "Testing Sequential"
    sequential=$(${IOPING} -RL . | grep -E '(iops|mdev)')
}

function get_ip() {
    echo
    echo "========== Network =========";
    echo
    echo "Gathering network information"
    ip=$(curl -s http://api.petabyet.com/ip)
}

function send_report() {
    echo "Sending Report to PetaByet.com..."
    echo
    echo
    echo "========== Benchmark Report ========="
    echo
    echo
    curl -k -d "ip=$ip&io=$dd&ioping=$ioping&seek=$seek&seq=$sequential&cpu=$cname&ram=$tram&disk=$disk&cores=$cores&swap=$swap&37=$geo37&2=$geo2&3=$geo3&40=$geo40&21=$geo21&11=$geo11&35=$geo35&32=$geo32&22=$geo22&34=$geo34&20=$geo20&24=$geo24&4=$geo4&17=$geo17&10=$geo10&41=$geo41&27=$geo27&13=$geo13&9=$geo9&7=$geo7&6=$geo6&18=$geo18&38=$geo38&36=$geo36&19=$geo19&31=$geo31&16=$geo16&5=$geo5&26=$geo26&12=$geo12&39=$geo39&23=$geo23&28=$geo28&30=$geo30&33=$geo33&1=$geo1&25=$geo25&8=$geo8&14=$geo14&15=$geo15&29=$geo29&pname=$pname&price=$price&provider=$provider&token=$token" https://www.petabyet.com/core/get.php
    echo
    echo
}

function readable_mem() {
    # This fucntion receives the param in MB.
    echo ${1} | awk '{ sum=$1 ; hum[1024]="GB"; for (x=1024; x>=1024; x/=1024){ if (sum>=x) { printf "%.2f %s\n",sum/x,hum[x];break } else { printf "%d MB\n", sum;break;} }}'
}

function readable_disk() {
    # This function receives the param in KB.
    echo ${1} | awk '{ sum=$1 ; hum[1024**3]="TB";hum[1024**2]="GB";hum[1024]="MB"; for (x=1024**3; x>=1024; x/=1024){ if (sum>=x) { printf "%.2f %s\n",sum/x,hum[x];break } }}'
}

function show_summary() {
    echo
    echo
    echo "--- 8< --- [cut here] --- 8< ---"
    echo

    echo "****** SERVER SPECS"
    echo "CPU model: "${cname}
    echo "CPU clock: "${cmhz}" MHz"
    echo "CPU cores: "${cores}
    echo "RAM: "$(readable_mem ${tram})
    echo "SWAP: "$(readable_mem ${swap})
    echo "Disk space: "$(readable_disk ${disk})

    echo
    echo

    echo "***** SPEED TESTS"
    echo "### North America"
    echo "SoftLayer, Dallas, USA: "${geo37}
    echo "ReliableSite, Piscataway, USA: "${geo40}
    echo "OVH, Beauharnois, Canada: "${geo11}
    echo "Softlayer, Washington, USA: "${geo22}
    echo "SoftLayer, San Jose, USA: "${geo3}

    echo

    echo "### Europe"
    echo "ThinkBroadband, London, United Kingdom: "${geo20}
    echo "Tele2, Stockholm, Sweden: "${geo24}
    echo "OVH, Roubaix, France: "${geo10}
    echo "Prometeus, Milan, Italy: "${geo41}
    echo "LeaseWeb, Frankfurt, Germany: "${geo9}
    echo "Interactive3D, Amsterdam, Netherlands: "${geo6}

    echo

    echo "### Asia"
    echo "SoftLayer, Singapore, Singapore: "${geo26}
    echo "Linode, Tokyo, Japan: "${geo12}

    echo

    echo "### Oceania"
    echo "RansomIT, Sydney, Australia: "${geo25}

    echo

    echo "### CDN"
    echo "CacheFly CDN Network: "${geo1}
    echo "Internode CDN Network: "${geo33}

    echo
    echo

    echo "***** I/O TESTS"
    echo "I/O speed (dd): "${dd}
    echo "IOPing: "${ioping}
    echo "Seek: "${seek}
    echo "Sequential: "${sequential}

    echo
    echo "--- 8< --- [cut here] --- 8< ---"
}

welcome_banner

# Let it begin...

echo "Starting..."
sleep 1

mkdir -p ${BENCHMARK_DIR}
pushd ${BENCHMARK_DIR}  >/dev/null

check_required_packages
setup_ioping

run_network_tests
server_specs
run_io_tests

# If we don't have all the required parameters, just show a clear text summary.
if [[ ${#} -ne 4 ]]; then
    show_summary
else
    get_ip
    send_report
fi

popd >/dev/null # petabyet
