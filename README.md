# ros2_devenv_builder

[![nightly](https://github.com/fujitatomoya/ros2_devenv_builder/actions/workflows/nightly.yml/badge.svg)](https://github.com/fujitatomoya/ros2_devenv_builder/actions/workflows/nightly.yml)

[ros2_devenv_builder](https://github.com/fujitatomoya/ros2_devenv_builder) creates ROS 2 builder container images for full source build, verifies and pushes them to [DockerHub](https://hub.docker.com/).

## Motivation

To catch up with mainline interfaces and development for each ROS distribution, sometimes it requires full source build with mainline head.
This is not usually required for ROS 2 application built on top of released distribution, but the development is dependent on `rolling` branch.
Or if you are developing ROS 2 core implementation such as `rmw` implementation or `rcl_logging_interfaces` implementation, it requires to catch up with mainline head to make sure it does not break the build or all tests pass.

The container images created by [ros2_devenv_builder](https://github.com/fujitatomoya/ros2_devenv_builder) installed all development dependencies and packages in the roof file system, that means we can just bind the development source code to the container and start building with it.

## When to re-create images

These development images are expected to have all dependent packages using `rosdep`.
That means once [ros2 repo](https://github.com/ros2/ros2) is updated or added with new packages, `rosdep` is required to rebuild to install all the dependent packages, and then release the images.

## Supported distributions

| ROS 2 distribution | Ubuntu base image |
| ------------------ | ----------------- |
| `humble`           | Jammy (22.04)     |
| `jazzy`            | Noble (24.04)     |
| `kilted`           | Noble (24.04)     |
| `lyrical`          | Resolute (26.04)  |
| `rolling`          | Resolute (26.04)  |

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
./scripts/image_builder.sh -t lyrical
```

## Nightly build and release

[nightly.yml](.github/workflows/nightly.yml) GitHub Actions workflow builds, verifies and releases all distribution images to [DockerHub](https://hub.docker.com/) every day (00:00 JST).
Each distribution runs as an independent job, so the images are always up to date, and if something breaks (e.g. new `rosdep` key, package change) it is visible as a failed job.
Images are pushed only after the verification succeeds, so [DockerHub](https://hub.docker.com/) always keeps the last known good image.

- Required repository secrets

  | Secret               | Description                                                                          |
  | -------------------- | ------------------------------------------------------------------------------------ |
  | `DOCKERHUB_USERNAME` | DockerHub account name, also used as image namespace (`<user>/ros2dev:<distro>`)     |
  | `DOCKERHUB_TOKEN`    | DockerHub [access token](https://docs.docker.com/security/for-developers/access-tokens/) with Read & Write permission |

- Manual trigger

  The workflow can also be triggered manually from the Actions tab (`Run workflow`), with a specific target distribution and with or without pushing to [DockerHub](https://hub.docker.com/).

- Local non-interactive use

  `image_builder.sh` logs in to [DockerHub](https://hub.docker.com/) non-interactively when `DOCKERHUB_TOKEN` is set, otherwise it prompts via `docker login`.

```bash
DOCKERHUB_USERNAME=<user> DOCKERHUB_TOKEN=<token> ./scripts/image_builder.sh -b -v -u -t rolling
```

## Reference

- https://docs.ros.org/en/rolling/Installation/Alternatives/Ubuntu-Development-Setup.html
