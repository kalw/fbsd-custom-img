# FreeBSD Custom Image Builder

This project automates building custom FreeBSD images with pre-configured flavors (e.g., desktop, poudriere).

## What It Does

- Downloads the latest FreeBSD release for your chosen architecture.
- Mounts the image and injects a custom installer configuration (`installerconfig`) for your selected flavor.
- Produces a bootable FreeBSD image with your settings and packages.
- Optionally, integrates with CI (CircleCI) to build and release images automatically.

## How to Generate a Custom Image

1. **Choose your flavor:**  
   Place your custom `installerconfig` in one of the flavor folders (`desktop`, `poudriere`, etc.)or create new one.

2. **Run all flavors, versions and archs:**  
   ```sh
   ./make.iso.with.installer.sh
   ```
   You can set environment variables to customize:
   - `FREEBSD_VERSION` (e.g., `14.0`) This is a comma separated list
   - `FREEBSD_ARCH` (e.g., `amd64/amd64` or `amd64/amd64,arm64/aarch64`) This is a comma separated list
   - `FREEBSD_FLAVOR` (e.g., `desktop`, `desktop,poudriere`)  This is a comma separated list

   Example:
   ```sh
   FREEBSD_VERSION=14.0 FREEBSD_ARCH=amd64/amd64 FREEBSD_FLAVOR=desktop ./make.iso.with.installer.sh
   ```

3. **Find your image:**  
   The resulting `.img.xz` files will be in the `artifact/` directory.

## Advanced: CI/CD

- The `.cirrus.yml` automates builds for multiple versions, architectures, and flavors.
- Artifacts are versioned and released in GitHub helped by `cog`.

---

For more details, check the script and installer configs in each flavor folder.
