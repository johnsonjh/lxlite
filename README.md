# lxLite

This is a port of **lxLite** to **Free Pascal**.

## Native build

Building **lxLite** requires a Unix-like shell environment, Python 3 (used
to transform the resource file format), and the Free Pascal compiler.

Native build on Unix-like platforms:

```sh
./build.sh
```

Build artifacts will be created in an appropriately named `./build/`
subdirectory.

## Notes

Other systems that offer **Free Pascal** (*e.g.*, AIX, OS/2, DOS, AmigaOS,
MorphOS, AROS, Haiku, Solaris, macOS, FreeBSD) are untested, but are likely
to "just work" or be easily supported.

## Cross-compilation

If the appropriate `binutils` and `fpc-units` packages are installed
cross-compilation is supported.  The following invocations have been confirmed
to produce working binaries on a Linux (Fedora 45 x86_64) host system:

```sh
sudo dnf install fpc fpc-units-aarch64-linux fpc-units-arm-linux \
fpc-units-i386-linux fpc-units-x86_64-linux fpc-units-i386-win32 \
fpc-units-x86_64-win64 fpc-cross-aarch64 fpc-cross-arm fpc-cross-i386
```

```sh
env FPCARCH="aarch64" FPCOS="linux" ./build.sh
env FPCARCH="arm"     FPCOS="linux" ./build.sh
env FPCARCH="i386"    FPCOS="linux" ./build.sh
env FPCARCH="x86_64"  FPCOS="linux" ./build.sh
```

```sh
env FPCARCH="i386"    FPCOS="win32" ./build.sh
env FPCARCH="x86_64"  FPCOS="win64" ./build.sh
```

## Downloads

[**Pre-built binaries are available to download.**](https://github.com/johnsonjh/lxlite/releases/latest/)

## License

**lxLite** is distributed under the terms of the
[GNU General Public License, version 2](COPYING).
