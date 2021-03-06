#!/bin/bash
set -e

./sanity_checks.sh

echo "Ensuring antigen is set up..."
if [ ! -f ~/.antigen.zsh ]; then
  curl https://cdn.rawgit.com/zsh-users/antigen/v1.1.0/bin/antigen.zsh > ~/.antigen.zsh
fi

echo "Ensuring Janus is set up..."
if [ ! -d ~/.vim/janus ]; then
  echo "Janus is not set up, installing now..."
  curl -L https://bit.ly/janus-bootstrap | bash
fi

echo "Ensuring Powerline is set up..."
if [ ! -d ~/.powerline ]; then
  rm -rf ~/.powerline || true
  echo "Cloning powerline..."
  git clone https://github.com/powerline/powerline.git ~/.powerline
  pushd ~/.powerline && \
    git checkout 6e2e0b2f9221fbff117be3d190f9293b40ba64cd && \
    popd
fi

echo "Updating submodules..."
pushd ~/.janus
git submodule update --init --recursive
popd

echo "Compiling YouCompleteMe..."

YCM_FLAGS=--clang-completer
check_go() {
  echo " - checking for go support..."
  if ! GOROOT=$(go run ./go/check_root.go); then
    echo " ! go check failed, skipping go support"
    return 0
  fi

  echo " - go root found: $GOROOT"
  echo " - checking cgo works..."
  if ! gcc -c -fPIC -o ./go/lib/lib.o ./go/lib/lib.c && \
       gcc -c -fPIC -shared -o ./go/liblib.so ./go/lib/lib.c; then
    echo " ! gcc failed to compile cgo test, skipping go support."
    return 0
  fi

  pushd ./go
  if ! GOVERSION=$(LD_LIBRARY_PATH=. go run ./check_cgo.go); then
    echo " ! cgo check failed, skipping go support"
    popd
    return 0
  fi
  popd

  echo " - go looks OK, enabling support"
  YCM_FLAGS="$YCM_FLAGS --gocode-completer"
  return 0
}

check_go

pushd ~/.janus/YouCompleteMe
./install.py $YCM_FLAGS
popd

echo "Done!"
