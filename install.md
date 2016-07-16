---
layout: page
title: Install
sidebar: false
highlight_first: false
permalink: /install/index.html
---

## Quickstart

### Docker

If you have [Docker](https://www.docker.com/), the fastest way to
install Regent is to run the official container:

{% highlight bash %}
docker run -ti stanfordlegion/regent
{% endhighlight %}

### Ubuntu

If you use Ubuntu, you can install Regent by running:

{% highlight bash %}
sudo apt-get install clang-3.5 libclang-3.5-dev llvm-3.5-dev
git clone -b master https://github.com/StanfordLegion/legion.git
cd legion/language
./install.py --debug
{% endhighlight %}

Complete instructions for installation follow below.

## Prerequisites

Regent requires:

  * Linux, macOS, or another Unix
  * A C++ 98 (or newer) compiler (GCC, Clang, Intel, or PGI) and GNU Make
  * Python 2.7 (or 3.x)
  * LLVM and Clang 3.5 **with headers**
      * Versions 3.6 and 3.8 also work, but are missing debug symbols in generated code

There are also a number of optional dependencies. For most users, we
recommend skipping these initially and installing them later on an
as-needed basis.

  * *Optional*: CUDA 5.0 or newer (for NVIDIA GPUs)
  * *Optional*: [GASNet](https://gasnet.lbl.gov/) (for networking, see
     [installation instructions](http://legion.stanford.edu/gasnet/))
  * *Optional*: HDF5 (for file I/O)

## Building

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

## Running

Regent includes a frontend interpreter which can be run with:

{% highlight bash %}
./regent.py <script>
{% endhighlight %}

For example:

{% highlight bash %}
./regent.py examples/circuit.rg
{% endhighlight %}

(Note: The Regent frontend can also be run without arguments to obtain
a [Terra](http://terralang.org)/[LuaJIT](http://luajit.org/)
shell. However, this mode is not very useful because of the way that
Terra language extensions works. Also, the Legion runtime is not
currently reentrant, making interactive use difficult.)
