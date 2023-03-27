# setupfiles

Setup scripts and configs for my computers.

## Mac

Shell scripts for setting up a new Mac, using [homebrew](https://brew.sh/) as the "package manager".

Shell profile for [oh-my-zsh](https://ohmyz.sh/), which includes my custom shell aliases and functions,
which should be copied to `~/.zshrc`.

## Windows

Powershell script for setting up a new Windows machine, using [choco](https://chocolatey.org/) as the "package manager".
Bash profile for Git Bash, which should be copied to `~/.bashrc`.

## Tool configs

Configs for various code formatting and linting tools that I regurarly use.
The dot prefix has been removed from some of the files here, so they are easier to interact with in Finder for example.

* Python: [pyproject.toml](./pyproject.toml) for [Black](https://github.com/psf/black) and [Ruff](https://github.com/charliermarsh/ruff) (combining flake8, isort and others)
* C++: [.clang-format](./.clang-format)
* Rust: [.rustfmt.toml](./.rustfmt.toml)
* Ruby: [.rubocop.yml](./.rubocop.yml) for [rubocop](https://github.com/rubocop/rubocop)
  * Primarily for [Fastlane](https://github.com/fastlane/fastlane)
* [Pre-commit](https://pre-commit.com/): [.pre-commit-config.yaml](./.pre-commit-config.yaml)
* [Editorconfig](https://editorconfig.org/): [.editorconfig](./.editorconfig)
