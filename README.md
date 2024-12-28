# dpp-automkstate.nvim

Automatically executes `dpp#make_state`.

## Usage

```lua
require 'dpp-automkstate'.setup('~/.cache/dpp/', '~/.config/nvim/dpp.ts') -- Set the dpp#make_state args (before calling watch)
require 'dpp-automkstate'.watch(vim.fn.stdpath 'config')                  -- Set a file/directory path to watch
-- require 'dpp-automkstate'.watch("~/dpp")                               -- If you want to watch multiple files/directories, call it multiple times
```

### Functions

- `setup`: the arguments are the same as `dpp#make_state` function
- `watch`: the argument is a file or directory path. Returns the autocmd ID

## Installation

### dpp.vim

```toml
[[plugins]]
repo = "gw31415/dpp-automkstate.nvim"
on_event = "BufWritePre"
lua_source = '''
require 'dpp-automkstate'.setup('~/.cache/dpp/', '~/.config/nvim/dpp.ts')
require 'dpp-automkstate'.watch(vim.fn.stdpath 'config')
'''
```

## License

Apache-2.0
