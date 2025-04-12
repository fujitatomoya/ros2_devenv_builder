# ros2_devenv_builder

[ros2_devenv_builder](https://github.com/fujitatomoya/ros2_devenv_builder) creates ROS 2 builder container images for full source build, verifies and pushes them to [DockerHub](https://hub.docker.com/).

## Motivation

To catch up with mainline interfaces and development for each ROS distribution, sometimes it requires full source build with mainline head.
This is not usually required for ROS 2 application built on top of released distribution, but the development is dependent on `rolling` branch.
Or if you are developing ROS 2 core implementation such as `rmw` implementation or `rcl_logging_interfaces` implementation, it requires to catch up with mainline head to make sure it does not break the build or all tests pass.

The container images created by [ros2_devenv_builder](https://github.com/fujitatomoya/ros2_devenv_builder) installed all development dependencies and packages in the roof file system, that means we can just bind the development source code to the container and start building with it.

## When to re-create images

These development images are expected to have all dependent packages using `rosdep`.
That means once [ros2 repo](https://github.com/ros2/ros2) is updated or added with new packages, `rosdep` is required to rebuild to install all the dependent packages, and then release the images.

## How to use

The following options can be executed at the same time.

- Create container images

  This creates the all supported distribution container images with required development packages. i.e) apt repository added, apt install all required packages, and rosdep update.

```bash
./scripts/image_builder.sh -b
```

- Verify container images

  This verifies that created container images are actually able to build the full source via `colcon build` before release to [DockerHub](https://hub.docker.com/).

```bash
./scripts/image_builder.sh -v
```

- Release container images

  This releases created container to [DockerHub](https://hub.docker.com/).

```bash
./scripts/image_builder.sh -u
```

- Target distribution

  This option allows you to build/release the specified ROS distribution only.

```bash
./scripts/image_builder.sh -t jazzy
```

## Reference

- https://docs.ros.org/en/rolling/Installation/Alternatives/Ubuntu-Development-Setup.html
