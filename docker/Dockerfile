# Build:
#  docker build --rm -f ./docker/Dockerfile --build-arg="ROS_DISTRO=rolling" \
#    --build-arg="SETUP_WS=/root/setup_ws" --build-arg="UBUNTU=noble" \
#    -t <user_name>/ros2dev:rolling .
#
# Usage:
#  docker pull <user_name>/ros2dev:rolling

# An ARG declared before a FROM is outside of a build stage,
# so it can’t be used in any instruction after a FROM.
# To use the default value of an ARG declared before the first FROM
# use an ARG instruction without a value inside of a build stage:
ARG ROS_DISTRO=rolling
ARG UBUNTU=noble
ARG SETUP_WS=/root/setup_ws

FROM ubuntu:${UBUNTU}

ARG ROS_DISTRO
ARG UBUNTU
ARG SETUP_WS

LABEL maintainer="Tomoya Fujita <tomoya.fujita825@gmail.com>"
LABEL version="1.0"
LABEL description="ros2 source builder docker image for ${ROS_DISTRO}"

SHELL ["/bin/bash","-c"]

COPY . ${SETUP_WS}

# All apt-get commands start with an update.
RUN apt-get update && apt-get upgrade -y

# Run ros2_devenv_builder/dev_env_setup.sh
RUN ${SETUP_WS}/scripts/dev_env_setup.sh ${ROS_DISTRO}

# Overwrite as environmental variables so that entrypoint can rely on those.
ENV ROS_DISTRO=${ROS_DISTRO}
#ENTRYPOINT ["/ros_entrypoint.sh"]
