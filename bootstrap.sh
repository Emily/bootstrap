#!/bin/bash
shopt -s extdebug

cd ~

brewList=""

echoGreen() {
  echo -e \\033[32m$1\\033[0m
}

gitClone() {
  local arity="$#"

  if [ "${arity}" == "2" ]
  then
    local destDir=$2
  else
    local destDir=$(basename /$1)
  fi

  if [ -d $destDir ]
  then
    echoGreen "$1 already cloned"
  else
    if [ "${arity}" == "2" ]
    then
      echo "cloning $1 to $destDir..."
      git clone git@github.com:$1 $destDir &> /dev/null
    else
      echo "cloning $1..."
      git clone git@github.com:$1 &> /dev/null
    fi
  fi
}

finstall() {
  echo "installing $2..."

  output=$(eval "printf '\n' | $1")

  which -s brew
  if [ $? -ne 0 ]
  then
    echo "failed to install $2"
    echo "${output}"
    exit 1
  fi
}

initBrewList() {
  brewList=$(brew list)
  brewTaps=$(brew tap)
}

checkBrewList() {
  split=$(basename $1)
  for item in $brewList
  do
    if [ "$split" == "$item" ]
    then
      return 0
    fi
  done

  return 1
}

brew_install() {
  checkBrewList $1

  if [ $? -ne 0 ]
  then
    echo "$1 not installed"
    finstall "brew install $1" $1
  else
    echoGreen "$1 already installed"
  fi
}

cask_install() {
  brew cask list 2>/dev/null | grep $1 &> /dev/null

  if [ $? -ne 0 ]
  then
    finstall "brew cask install $1" "cask $1"
  else
    echoGreen "cask $1 already installed"
  fi
}

checkBrewTaps() {
  for item in $brewTaps
  do
    if [ "$1" == "$item" ]
    then
      return 0
    fi
  done

  return 1
}

brew_tap() {
  checkBrewTaps $1

  if [ $? -ne 0 ]
  then
    echo "tapping $1"
    brew tap $1 git@github.com:$1.git &> /dev/null
  else
    echoGreen "already tapped $1"
  fi
}

which -s brew

if [ $? -ne 0 ]
then
  finstall '/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"' "homebrew"
else
  echoGreen "brew already installed"
fi

if [ -e ~/.ssh/id_rsa ]
then
  echoGreen "ssh key already exists"
else
  echo "generating ssh key..."
  ssh-keygen
fi

for i in 1 2 3
do
  ssh -oStrictHostKeyChecking=no git@github.com &> /dev/null
  if [ $? -eq 1 ]
  then
    break
  fi
  cat ~/.ssh/id_rsa.pub | pbcopy
  echo "please upload public key to github (and then press return)"
  read -n 1
done

initBrewList

brew_install chruby
brew_install ruby-install
brew_install tmux
brew_install vim
brew_install zsh
brew_install reattach-to-user-namespace
brew_install mysql
brew_install libxml2
brew_install tree
brew_install pkg-config
brew_install protobuf
brew_install glm

brew_tap burntsushi/ripgrep
brew_tap homebrew/services

brew_install burntsushi/ripgrep/ripgrep-bin

if [ -d ~/.rubies/ruby-2.4.1 ]
then
  echoGreen "ruby 2.4.1 already installed"
else
  echo "installing ruby 2.4.1"
  ruby-install -j4 ruby 2.4.1
fi

# cask_install iterm2
cask_install hyper

source /usr/local/share/chruby/chruby.sh

chruby 2.4.1 &> /dev/null

gem which homesick &> /dev/null

if [ $? -ne 0 ]
then
  echo "installing homesick..."
  gem install homesick &> /dev/null
else
  echoGreen "homesick already installed"
fi

homesick status dotfiles &> /dev/null

if [ $? -ne 0 ]
then
  echo "cloning dotfiles"
  homesick clone git@github.com:emily/dotfiles &> /dev/null
  homesick link dotfiles &> /dev/null
  pushd "$HOME/.vim/bundle/vimproc.vim" &> /dev/null
  make &> /dev/null
  popd &> /dev/null
else
  echoGreen "dotfiles already cloned"
fi

gitClone "mbadolato/iTerm2-Color-Schemes"
gitClone "creationix/nvm" "$HOME/.nvm"

pushd "$HOME/.nvm" &> /dev/null
git checkout "v0.33.11" &> /dev/null
source nvm.sh
popd &> /dev/null

which node &> /dev/null
if [ $? -ne 0 ]
then
  echo "installing node..."
  nvm install node
else
  echoGreen "node already installed"
fi
