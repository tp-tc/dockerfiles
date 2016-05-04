FROM ubuntu:14.04
MAINTAINER Philipp Kewisch "mozilla@kewis.ch"

# Install Thunderbird build dependencies.
# Packages after "mercurial" are from https://dxr.mozilla.org/mozilla-central/source/python/mozboot/mozboot/debian.py
RUN apt-get update -q && apt-get upgrade -qy && apt-get install -qy clang gdb git mercurial autoconf2.13 build-essential ccache python-dev python-pip python-setuptools unzip uuid zip libasound2-dev libcurl4-openssl-dev libdbus-1-dev libdbus-glib-1-dev libgconf2-dev libgtk2.0-dev libgtk-3-dev libiw-dev libnotify-dev libpulse-dev libxt-dev mesa-common-dev python-dbus yasm xvfb
ENV CC clang
ENV CXX clang++
ENV SHELL /bin/bash

# Don't be root.
RUN useradd -m user
USER user
ENV HOME /home/user
WORKDIR /home/user

# Download Thunderbird's source code.
RUN hg clone https://hg.mozilla.org/comm-central/ thunderbird
WORKDIR thunderbird
RUN python client.py checkout

# Add .mozconfig file.
RUN echo "# Thunderbird build options." >> .mozconfig \
 && echo "ac_add_options --enable-application=mail" >> .mozconfig \
 && echo "ac_add_options --enable-calendar" >> .mozconfig \
 && echo "ac_add_options --disable-crashreporter" >> .mozconfig \
 && echo "ac_add_options --enable-extensions=default,inspector" >> .mozconfig \
 && echo "ac_add_options --with-ccache" >> .mozconfig \
 && echo "mk_add_options AUTOCLOBBER=1" >> .mozconfig \
 && echo "" >> .mozconfig \
 && echo "# Building with clang is faster." >> .mozconfig \
 && echo "export CC=clang" >> .mozconfig \
 && echo "export CXX=clang++" >> .mozconfig

# Set up mercurial so mach doesn't complain
RUN mkdir -p /home/user/.mozbuild && ./mozilla/mach mercurial-setup -u

# Build Thunderbird.
RUN ./mozilla/mach build