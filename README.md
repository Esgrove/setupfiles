# Setup files

Setup scripts and configs for my computers.

## Mac

Shell scripts for setting up a new Mac,
using [homebrew](https://brew.sh/) as the "package manager".

Shell profile [zshrc.sh](./zshrc.sh) for [oh-my-zsh](https://ohmyz.sh/),
which includes my custom shell aliases and functions,
which should be copied to `~/.zshrc`.

## Windows

PowerShell script for setting up a new Windows machine,
using [Scoop](https://scoop.sh/) as the "package manager".

Bash profile [bashrc.sh](./bashrc.sh) for Git Bash,
which should be copied to `~/.bashrc`.

## Ubuntu (WSL)

PowerShell script which in turns runs a bash shell script to set up Ubuntu for Windows Subsystem for Linux.

Shell profile [zshrc_ubuntu.sh](./zshrc_ubuntu.sh) for [oh-my-zsh](https://ohmyz.sh/),
which should be copied to `~/.zshrc`.

## Tool configs

Configs for various code formatting and linting tools that I use regularly.
The dot prefix has been removed from some files here,
so they are easier to interact with in macOS Finder for example.

* Python: [pyproject.toml](./pyproject.toml)
* C++: [.clang-format](./.clang-format) and [.clang-tidy](./.clang-tidy)
* Rust: [.rustfmt.toml](./.rustfmt.toml)
* Ruby: [.rubocop.yml](./.rubocop.yml) for [rubocop](https://github.com/rubocop/rubocop)
  * Primarily for [Fastlane](https://github.com/fastlane/fastlane)
* [Pre-commit](https://pre-commit.com/): [.pre-commit-config.yaml](./.pre-commit-config.yaml)
* [Editorconfig](https://editorconfig.org/): [.editorconfig](./.editorconfig)
