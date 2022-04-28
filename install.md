---
layout: page
title: Install
sidebar: false
highlight_first: false
permalink: /install/index.html
---

  * [Quickstart](#quickstart)
      * [Ubuntu](#ubuntu)
      * [macOS](#macos)
      * [Other Systems](#other-systems)
  * [Prerequisites](#prerequisites)
  * [Building](#building)
  * [Running](#running)
  * [Development Environment](#development-environment)

# Quickstart

These quickstart instructions describe how to install Regent on Ubuntu
and macOS, respectively.

## Ubuntu

If you use Ubuntu, you can install Regent by running:

{% highlight bash %}
# install dependencies
sudo apt-get install build-essential cmake git wget
wget https://github.com/terralang/llvm-build/releases/download/llvm-13.0.0/clang+llvm-13.0.0-x86_64-linux-gnu.tar.xz
tar xf clang+llvm-13.0.0-x86_64-linux-gnu.tar.xz
export CMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH:$PWD/clang+llvm-13.0.0-x86_64-linux-gnu"

# download and build Regent
git clone -b master https://github.com/StanfordLegion/legion.git
cd legion/language
./install.py --debug --rdir=auto

# run Regent example
./regent.py examples/circuit_sparse.rg
{% endhighlight %}

(These instructions have been tested on Ubuntu 18.04 and 20.04.)

## macOS

If you use macOS, you can install Regent by running:

{% highlight bash %}
# install XCode command-line tools
sudo xcode-select --install

# download CMake
curl -L -O https://github.com/Kitware/CMake/releases/download/v3.22.2/cmake-3.22.2-macos-universal.tar.gz
tar xfz cmake-3.22.2-macos-universal.tar.gz
export PATH="$PATH:$PWD/cmake-3.22.2-macos-universal/CMake.app/Contents/bin"

# download LLVM
curl -L -O https://github.com/terralang/llvm-build/releases/download/llvm-13.0.0/clang+llvm-13.0.0-x86_64-apple-darwin.tar.xz
tar xfJ clang+llvm-13.0.0-x86_64-apple-darwin.tar.xz
export CMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH:$PWD/clang+llvm-13.0.0-x86_64-apple-darwin"

# environment variables needed to build/run Regent
export INCLUDE_PATH="$(xcrun --sdk macosx --show-sdk-path)/usr/include"
export CXXFLAGS="-std=c++11"

# download and build Regent
git clone -b master https://github.com/StanfordLegion/legion.git
cd legion/language
./install.py --debug --rdir=auto

# run Regent example
./regent.py examples/circuit_sparse.rg
{% endhighlight %}

(These instructions have been tested on macOS 11.6 on an x86 Mac.)

## Other Systems

Complete instructions for installation follow below.

# Prerequisites

Regent requires:

  * Linux, macOS, or another Unix
  * A C++ 11 (or newer) compiler (GCC, Clang, Intel, or PGI) and GNU Make
  * Python 3.5 or newer
  * LLVM and Clang **with headers**:
      * LLVM 13.0 is recommended
      * See the [version support table](https://github.com/terralang/terra#supported-llvm-versions) for more details
      * Pre-built binaries are available [here](https://github.com/terralang/llvm-build/releases)
  * *Optional (but recommended)*: CMake 3.5 or newer

There are also a number of optional dependencies. For most users, we
recommend skipping these initially and installing them later on an
as-needed basis.

  * *Optional*: CUDA 7.0 or newer (for NVIDIA GPUs)
  * *Optional*: [GASNet](https://gasnet.lbl.gov/) (for networking, see
     [installation instructions](http://legion.stanford.edu/gasnet/))
  * *Optional*: HDF5 (for file I/O)

# Building

Regent includes a self-installer which downloads
[Terra](http://terralang.org/) and builds the Regent compiler. Run:

{% highlight bash %}
git clone -b master https://github.com/StanfordLegion/legion.git
cd legion/language
./install.py --debug
{% endhighlight %}

For other installation options (including multi-node and GPU
configurations), see the
[README](https://github.com/StanfordLegion/legion/blob/master/language/README.md).

# Running

Regent includes a frontend interpreter which can be run with:

{% highlight bash %}
./regent.py <script>
{% endhighlight %}

For example:

{% highlight bash %}
./regent.py examples/circuit_sparse.rg
{% endhighlight %}

(Note: The Regent frontend can also be run without arguments to obtain
a [Terra](http://terralang.org)/[LuaJIT](http://luajit.org/)
shell. However, this mode is not very useful because of the way that
Terra language extensions works. Also, the Legion runtime is not
currently reentrant, making interactive use difficult.)

# Development Environment

Regent syntax highlighting modes are available for the following
editors:

  * [Emacs](https://github.com/StanfordLegion/regent-mode)
  * [Vim](https://github.com/StanfordLegion/regent.vim)
