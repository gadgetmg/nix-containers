# Nix Container Images

This repository uses Nix to manage reproducible container images.

## Prerequisites

Before building, ensure the following are installed:

- Nix (or NixOS)

## Local Development

Launch a development shell using `nix develop`. This will ensure the correct version of the tools, like Just, are available in the session.

## Package and Tagging Structure

The repository packages are structured in `packages.x86_64-linux` and are tagged based on their name, which includes version numbers and runtime/OS specifications.

- **Versioned Tags:** e.g., `image-retroarch.1.22.2`
- **Specific Tags:** e.g., `image-steam.1.0.0.85-gamescope-nixos26.05.20260401.6201e20`
- **Aliases:** e.g., `image-retroarch.latest` or `image-steam.latest`

## Building and Managing Container Images

All commands require the image name as a parameter, but `*-all` recipes handle all packages.

### Building the Derivation

The `just build IMAGE` command runs `nix build` to create a reproducible Nix derivation, which is the source for your container image.

```bash
just build IMAGE
```

_(Note: This step only creates the derivation; it does not build a runnable Docker image.)_

### Running Locally

To obtain the image locally and run it with Docker:

```bash
# Get the image into the local Docker daemon
just copy-docker IMAGE

# Run the container
docker run -d --name my-service my-service-image:latest
```

It's not necessary to build the derivation first manually, as the Just recipe requires the build as a prerequisite.

### Pushing to Registry

To push the image to the GitHub Container Registry:

1. **Login:**

   ```bash
   just login
   ```

2. **Push Image:**

   ```bash
   just copy-registry IMAGE
   ```

For comprehensive builds (all packages), use `just copy-docker-all` or `just copy-registry-all`. For more details on the Nix configuration, please refer to `default.nix` or the relevant Nix configuration files.
