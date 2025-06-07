#!/bin/bash

#####################################################################
# ros2_devenv_builder
#
# This script installs dependent packages for source build for target distribution.
#####################################################################

##################
# Configurations #
##################

ros_distros=(
    "humble"
    "jazzy"
    "kilted"
    "rolling"
)

# for Jazzy, Kilted and Rolling
noble_development_packages=(
    "python3-flake8-blind-except"
    "python3-flake8-class-newline"
    "python3-flake8-deprecated"
    "python3-mypy"
    "python3-pip"
    "python3-pytest"
    "python3-pytest-cov"
    "python3-pytest-mock"
    "python3-pytest-repeat"
    "python3-pytest-rerunfailures"
    "python3-pytest-runner"
    "python3-pytest-timeout"
    "ros-dev-tools"
)

# for Humble
jammy_development_packages=(
    "python3-flake8-blind-except"
    "python3-flake8-builtins"
    "python3-flake8-class-newline"
    "python3-flake8-comprehensions"
    "python3-flake8-deprecated"
    "python3-flake8-docstrings"
    "python3-flake8-import-order"
    "python3-flake8-quotes"
    "python3-pip"
    "python3-pytest-cov"
    "python3-pytest-repeat"
    "python3-pytest-rerunfailures"
    "ros-dev-tools"
)

########################
# Function Definitions #
########################

function mark {
    export $1=`pwd`;
}

function exit_trap() {
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    if [ $? != 0 ]; then
        echo "Command [$BASH_COMMAND] is failed"
        exit 1
    fi
}

function get_ubuntu_version () {
    trap exit_trap ERR
    echo "[${FUNCNAME[0]}]: get ubuntu version."
    UBUNTU_VERSION=$(grep '^VERSION_ID=' /etc/os-release | awk -F'=' '{print $2}' | tr -d '"')
}

function locale_setup() {
    trap exit_trap ERR
    echo "/// ---------- [${FUNCNAME[0]}]: setting up locale."
    apt update && apt install -y locales
    locale-gen en_US en_US.UTF-8
    update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    export LANG=en_US.UTF-8
    echo "export LANG=en_US.UTF-8" >> ~/.bashrc
    # verify locale setting
    locale
}

function enable_repository() {
    trap exit_trap ERR
    echo "/// ---------- [${FUNCNAME[0]}]: enable Ubuntu Universe and ROS 2 apt repositories."
    apt install -y software-properties-common
    # add repositories
    add-apt-repository -y universe
    apt update && apt install curl -y
    export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
    curl -L -s -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb"
    apt install /tmp/ros2-apt-source.deb
    rm -f /tmp/ros-apt-source.deb
    # install development packages
    if [ "$target_distro" = "humble" ]; then
        echo "/// ---------- [${FUNCNAME[0]}]: install Ubuntu Jammy packages."
        development_packages=("${jammy_development_packages[@]}")
    else
        echo "/// ---------- [${FUNCNAME[0]}]: install Ubuntu Noble packages."
        development_packages=("${noble_development_packages[@]}")
    fi
    apt update && apt install -y "${development_packages[@]}"
}

function rosdep_setup() {
    trap exit_trap ERR
    echo "/// ---------- [${FUNCNAME[0]}]: setting up rosdep and install dependent packages for full build."
    temp_dir=$(create_temp_folder)
    mkdir -p ${temp_dir}/src
    cd ${temp_dir}
    vcs import --input https://raw.githubusercontent.com/ros2/ros2/${target_distro}/ros2.repos src
    apt upgrade -y
    rosdep init
    rosdep update
    # temporarily avoids rosidl_runtime_rs dependency.
    # see more details at https://github.com/ros2/ros2/issues/1693
    rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 rti-connext-dds-7.3.0 urdfdom_headers rosidl_runtime_rs"
    # ignore RTI Connext dependencies in default
    #rosdep install --from-paths src --ignore-src -y --skip-keys "fastcdr rti-connext-dds-6.0.1 rti-connext-dds-7.3.0 urdfdom_headers"
    cd -
    rm -rf ${temp_dir}
}

function create_temp_folder() {
    trap exit_trap ERR
    temp_folder=$(mktemp -d -p "$(pwd)" XXXXXX)
    echo $temp_folder
}

function print_usage() {
    echo "Usage: $0 [target_distro]"
    echo "  target_distro: The target ROS 2 distribution (default: rolling)"
}

########
# Main #
########

export DEBIAN_FRONTEND=noninteractive

# optional argument to specify the target ROS 2 distribution
target_distro=${1:-"rolling"}
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    print_usage
    exit 0
fi

# Check if the provided target_distro is valid
if [[ ! " ${ros_distros[*]} " =~ " ${target_distro} " ]]; then
    echo "Error: Invalid target distribution option. Must be one of: ${ros_distros[*]}"
    print_usage
    exit 1
fi

# Check the distro is appropriate for the Ubuntu version
get_ubuntu_version
if [ "$target_distro" = "humble" ] && [ "$UBUNTU_VERSION" != "22.04" ]; then
    echo "Error: ROS 2 Humble requires Ubuntu 22.04."
    exit 1
elif [[ "$target_distro" = "jazzy" || "$target_distro" = "kilted" || "$target_distro" = "rolling" ]] && [ "$UBUNTU_VERSION" != "24.04" ]; then
    echo "Error: ROS 2 Jazzy and Rolling require Ubuntu 24.04."
    exit 1
fi

# mark the working space root directory, so that we can come back anytime with `cd $there`
mark there

# set the trap on error
trap exit_trap ERR

# call install functions in sequence
locale_setup
enable_repository
rosdep_setup

exit 0
