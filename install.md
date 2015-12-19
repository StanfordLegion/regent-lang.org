---
layout: page
title: Install
sidebar: false
highlight_first: false
permalink: /install/index.html
---

## Docker

If you have [Docker](https://www.docker.com/), the fastest way to
install Regent is to run the official container:

{% highlight bash %}
docker run -ti stanfordlegion/regent
{% endhighlight %}

Otherwise, you can follow the instructions below to build and install
Regent locally:

## Prerequisites

Regent depends on:

  * Linux, Mac OS X, or another Unix.
  * Python >= 2.7 (for the self-installer and test suite).
  * A C++ 98 compiler (GCC, Clang, Intel, or PGI) and GNU Make.
  * Clang and LLVM **with headers**. As of December 2015, LLVM 3.5 is
    recommended; 3.6 works but is missing debug symbols. The binary
    packages on
    [LLVM.org](http://llvm.org/releases/download.html#3.5.2) appear to
    work well.
  * Other dependencies ([Terra](http://terralang.org/),
    [Legion](http://legion.stanford.edu/)) are downloaded
    automatically by the self-installer.

## Building

The Regent repository includes a self-installer which downloads and
builds the Regent compiler. Run:

{% highlight bash %}
git clone -b master https://github.com/StanfordLegion/legion.git
cd legion/language
./install.py --debug
{% endhighlight %}

For GPUs, clusters, and other installation options, see the
[README](https://github.com/StanfordLegion/legion/blob/master/language/README.md).

## Running

Regent includes a frontend interpreter which can be run with:

{% highlight bash %}
./regent.py <script.rg>
{% endhighlight %}

(Note: The Regent frontend can also be run without arguments to obtain
a [Terra](http://terralang.org)/[LuaJIT](http://luajit.org/)
shell. However, this mode is not very useful because of the way that
Terra language extensions works. Also, the Legion runtime is not
currently reentrant, making interactive use difficult.)