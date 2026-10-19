# Blobdrop

[![Continuous Integration](https://github.com/vimpostor/blobdrop/actions/workflows/ci.yml/badge.svg)](https://github.com/vimpostor/blobdrop/actions/workflows/ci.yml)

Drag and drop your files directly from the terminal.

https://github.com/vimpostor/blobdrop/assets/21310755/1957b6a7-475c-4930-80b9-18564ef39eb9


# Installation

Note: For Arch Linux users there is an [AUR package](https://aur.archlinux.org/packages/blobdrop-git), for Nix users there is a [flake](flake.nix) available and an official package in [nixpkgs](https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/bl/blobdrop/package.nix).
You can also download an AppImage from the [latest release](https://github.com/vimpostor/blobdrop/releases/latest).

## Building from source

Make sure you have a C++23 compiler and the latest Qt with the Declarative and Svg modules installed.

```bash
cmake -B build
cmake --build build

# install the build/blobdrop binary
cmake --install build
```

X11 terminal lowering is enabled automatically on Unix (except macOS) when `pkg-config` finds the `xcb` and `xcb-ewmh` development packages. Otherwise, it is omitted; Qt still supports running Blobdrop on X11 without it.

## Building Linux packages

Configure and build once, then select a CPack generator:

```bash
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build
cpack --config build/CPackConfig.cmake -G AppImage -B build/packages
cpack --config build/CPackConfig.cmake -G DEB -B build/packages
cpack --config build/CPackConfig.cmake -G RPM -B build/packages
```

AppImage requires CMake/CPack 4.2 or newer, `appimagetool`, and `patchelf` 0.19.2 or newer (older versions can corrupt current distro libraries). To select a custom tool, configure with `-DQT_DEPLOY_PATCHELF_EXECUTABLE=/path/to/patchelf`. In containers without FUSE, use `APPIMAGE_EXTRACT_AND_RUN=1` when `appimagetool` is itself an AppImage.

AppImage bundles Qt libraries, plugins, and QML imports using Qt's CMake deployment support, while using the host's C/C++ runtimes and graphics drivers. Install the Qt Wayland runtime on the build host to include its native Wayland backend. Build on the oldest distribution you intend to support.

DEB packages require `dpkg-shlibdeps` (from `dpkg-dev`); RPM packages require `rpmbuild`. Build native packages on the target distribution so their automatically detected library dependencies match it. Qt is supplied by the distribution; additional QML and plugin dependencies are declared explicitly. The RPM defaults use Fedora package names; override `CPACK_RPM_PACKAGE_REQUIRES` for other RPM distributions.

Set the package maintainer when configuring release packages, for example `-DCPACK_PACKAGE_CONTACT="Your Name <you@example.org>"`. CPack writes packages and SHA256 checksums to the selected output directory. Ordinary installation does not bundle runtime libraries.

# Usage

```bash
blobdrop [files-to-drag]
```

For more options see `blobdrop -h` or the man page `blobdrop(1)`.

## Features

- Start drag automatically without a GUI
- Hide the parent terminal emulator while dragging
- Automatically quit once all paths have been dragged
- Auto-hide the GUI while dragging
- Show mime icons and thumbnails for media
- Drag all files at once
- Preview files with a single click
- Shell completions
- Act as a sink and print dropped files to the terminal
- Pipe filenames asynchronously into stdin

### Frontends

Blobdrop implements multiple frontends to drag the files from:

- [From a normal window](https://github.com/vimpostor/blobdrop/assets/21310755/d86f5039-05cd-4444-9e43-cc51cf4073db)
- [Inside a desktop notification](https://github.com/vimpostor/blobdrop/assets/21310755/482b4bc1-2f15-43e3-b980-1f573c494a91), using the `x-kde-urls` Notifications extension
- [As an immediate drop to a click location](https://user-images.githubusercontent.com/21310755/266832800-519773b6-d154-4fd7-9faf-dfb25217055c.mp4), this works on all EWMH-compliant window managers
- As clipboard content, allowing to paste the file URIs to other programs
- As an [OSC8 hyper link](https://github.com/vimpostor/blobdrop/commit/3ba601c690571460fc8cd130abb57c7a15c67cf1) in the terminal emulator, but currently there exists no terminal emulator that can drag and drop OSC8 links

# Alternatives

- [dragon](https://github.com/mwh/dragon) - A GTK implementation of the same concept
- [clidrag](https://github.com/rkevin-arch/CLIdrag) - A CLI-only implementation
- [ripdrag](https://github.com/nik012003/ripdrag) - Like dragon with GTK, but rewritten in Rust

Note that none of these alternatives provide a workflow similar to blobdrop's immediate frontend (except clidrag, but it lacks many UX improvements).
