#!/bin/sh

set -e

setup_debian() {
  which wget || sudo apt-get -q -y -f install wget
  which gpg || sudo apt-get -q -y -f install gnupg
  which lsb_release || sudo apt-get -q -y -f install lsb-release
  codename=$(lsb_release -c | awk '{print($2)}')
  if type prepare_$codename >/dev/null 2>&1; then
    prepare_$codename
  else
    echo "WARNING: no specific preparation steps for $codename"
  fi

  if [ ! -f /etc/apt/sources.list.d/analizo.list ]; then
    echo "deb http://www.analizo.org/download/ ./" | sudo sh -c 'cat > /etc/apt/sources.list.d/analizo.list'
    wget -O - http://www.analizo.org/download/signing-key.asc | sudo apt-key add -
  fi
  which apt-file || sudo apt-get -q -y -f install apt-file
  sudo apt-get update
  sudo apt-file update

  sudo apt-get -q -y -f install dh-make-perl libdist-zilla-perl liblocal-lib-perl cpanminus

  # install Doxyparse build dependencies and define "master" as Doxyparse version to install
  sudo apt-get -q -f -y install flex bison cmake build-essential python
  export ALIEN_DOXYPARSE_VERSION=master

  packages=$(locate_package $(dzil authordeps))
  sudo apt-get -q -y -f install $packages
  dzil authordeps --missing | cpanm --notest

  packages=$(locate_package $(dzil listdeps))
  sudo apt-get -q -y -f install $packages
  dzil listdeps --missing | cpanm --notest
}

locate_package() {
  packages=
  for module in $@; do
    package=$(dh-make-perl locate $module | grep 'package$' | grep ' is in ' | sed 's/.\+is in \(.\+\) package/\1/')
    packages="$packages $package"
  done
  echo $packages
}

prepare_ubuntu() {
  if ! grep -q ZeroMQ Makefile.PL; then
    # only needed while we depend on ZeroMQ
    return
  fi
  apt-get install -q -y libzeromq-perl
}

prepare_precise() {
  prepare_ubuntu
}

prepare_quantal() {
  prepare_ubuntu
}

prepare_trusty() {
  prepare_ubuntu
}

# FIXME share data with Makefile.PL/dist.ini
needed_programs='
  cpanm
  git
  pkg-config
'

needed_libraries='
  uuid
  libzmq
'

check_non_perl_dependencies() {
  failed=false

  for program in $needed_programs; do
    printf "Looking for $program ... "
    if ! which $program; then
      echo "*** $program NOT FOUND *** "
      failed=true
    fi
  done

  for package in $needed_libraries; do
    printf "Looking for $package ... "
    if pkg-config $package; then
      echo OK
    else
      echo "*** ${package}-dev NOT FOUND ***"
      failed=true
    fi
  done

  if [ "$failed" = 'true' ]; then
    echo
    echo "ERROR: missing dependencies"
    echo "See HACKING for tips on how to install missing dependencies"
    exit 1
  fi
}

setup_generic() {
  check_non_perl_dependencies
  dzil listdeps | cpanm
}

setup_archlinux() {
  cpanminus_mirror="http://mirror.f4st.host/archlinux/community/os/x86_64/cpanminus-1.7044-2-any.pkg.tar.xz"
  gnuplot_mirror="http://mirror.f4st.host/archlinux/extra/os/x86_64/gnuplot-5.2.6-2-x86_64.pkg.tar.xz"
  dzil_snapshot="https://aur.archlinux.org/cgit/aur.git/snapshot/perl-dist-zilla.tar.gz"

  which cpanminus || install_aur_mirror $cpanminus_mirror
  which gnuplot || install_aur_mirror $gnuplot_mirror
  install_aur_snapshot $dzil_snapshot
  cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
  cpanm Alien::Gnuplot
  cpanm Graph::Writer::DSM
  cpanm Dist::Zilla::Plugin::VersionFromModule

  # comment line 67 and 68 of dist.ini
  sed -i '67,68 s/^/;/' dist.ini
  setup_generic
}

# $1 - mirror url
install_aur_mirror() {
    curl -L -O $1
    pkg=${1##*/}
    sudo pacman -U $pkg
    rm $pkg
}

# $1 - snapshot url
install_aur_snapshot() {
    curl -L -O $1
    tarball=${1##*/}
    tar -xzvf $tarball
    pkg=${tarball%%.*}
    cd $pkg
    makepkg -Acs
    sudo pacman -U *.pkg.tar.xz
    cd ..
    rm -r $pkg
    rm $tarball
}
              
if [ ! -f ./bin/analizo ]; then
  echo "Please run this script from the root of Analizo sources!"
  exit 1
fi

force_generic=false
if [ "$1" = '--generic' ]; then
  force_generic=true
fi

if [ -x /usr/bin/dpkg -a -x /usr/bin/apt-get -a "$force_generic" = false ]; then
  setup_debian
elif [ -f /etc/arch-release ]; then
  setup_archlinux
else
  setup_generic
fi
