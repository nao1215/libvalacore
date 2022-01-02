[![Build](https://github.com/nao1215/libcore/actions/workflows/build.yml/badge.svg?branch=main)](https://github.com/nao1215/libcore/actions/workflows/build.yml)
[![UnitTest](https://github.com/nao1215/libcore/actions/workflows/unit_test.yml/badge.svg?branch=main)](https://github.com/nao1215/libcore/actions/workflows/unit_test.yml)
![GitHub](https://img.shields.io/github/license/nao1215/libcore)

# libcore - basic library for vala
The basic API of Vala language is provided by GLib and libgee. However, I think Vala's API difficult to use. It looks like there are many inconsistent libraries compared to Python, Java and Golang.  

So, let's create the easy-to-use Vala basic API library.  

# How to build (install)
```
$ sudo apt update
$ sudo apt install valac build-essential meson valadoc libglib2.0-0 ninja

$ git clone https://github.com/nao1215/libcore.git
$ cd libcore
$ meson build
$ cd build
$ ninja
$ sudo ninja install
```

# Valadoc
[Click here for libcore's Valadoc.](https://nao1215.github.io/libcore/)
