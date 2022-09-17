# zabort

Abort functionality for zsh

## Installation

### Homebrew

```sh
brew install paltherr/zsh/zabort
```

### Manual

```sh
cd /usr/local/opt
git clone https://github.com/paltherr/zabort.git
cd /usr/local/bin
ln -s ../opt/zabort/src/bin/zabort.zsh
cd /usr/local/share/zsh/site-functions
ln -s ../../../opt/zabort/src/functions/abort
ln -s ../../../opt/zabort/src/functions/usage
```
