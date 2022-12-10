# qdr.nvim

Quickly run labelled commands via a fuzzy finder without leaving Neovim.

## Requirements

- `fzf` binary in `$PATH`
- lyaml lua module (only if you are contributing)

## Installation

```
use 'vijaymarupudi/nvim-fzf'
use 'ZacxDev/qdr.nvim'
```

## Usage

![Imgur](https://i.imgur.com/CnNgyCL.gif)

```vimscript
" Open the qdr picker
:Qdr
```

## Example qdr.yml

```yml
Run Go Generate: go generate ./...
Run Tests: go test ./...
```

## Roadmap

 - async execution in a floating window + Command to close floating window
 - break up functions more
 - tests

