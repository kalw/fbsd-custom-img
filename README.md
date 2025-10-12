# FreeBSD Custom Image Builder

This project automates building custom FreeBSD images with pre-configured flavors (e.g., desktop, poudriere).

## What It Does

- Downloads the latest FreeBSD release for your chosen architecture.
- Mounts the image and injects a custom installer configuration (`installerconfig`) for your selected flavor.
- Produces a bootable FreeBSD image with your settings and packages.
- Optionally, integrates with CI (CircleCI) to build and release images automatically.

## How to Generate a Custom Image

1. **Choose your flavor:**  
   Place your custom `installerconfig` in one of the flavor folders (`desktop-install/`, `poudriere-install/`, etc.).

2. **Run the build script:**  
   ```sh
   ./make.iso.with.installer.sh
   ```
   You can set environment variables to customize:
   - `FREEBSD_VERSION` (e.g., `14.0`)
   - `FREEBSD_ARCH` (e.g., `amd64/amd64` or `arm64/aarch64`)
   - `FREEBSD_FLAVOR` (e.g., `desktop`, `poudriere`)

   Example:
   ```sh
   FREEBSD_VERSION=14.0 FREEBSD_ARCH=amd64/amd64 FREEBSD_FLAVOR=desktop ./make.iso.with.installer.sh
   ```

3. **Find your image:**  
   The resulting `.img` file will be in the current directory.

## Advanced: CI/CD

- The `.circleci/config.yml` automates builds for multiple versions, architectures, and flavors.
- Artifacts are versioned and released via GitHub.

---

For more details, check the script and installer configs in each flavor folder.
