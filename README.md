[resurrect with workpaces.nvim](https://i.imgur.com/bTKtA7v.gif)

# Resurrect your neovim session

Yet another session plugin? not really this plugin doesnt use mksession and didnt actually save your "session" its just list all the files that you opened, sort it according to last modified time then save it for you to resurrect them later.

# Why?

mksession sucks. It saves everything, including Nvim-Tree too.

# Setup

Just install it with whatever your plugin manager is, example for lazy.nvim

```
{
    'Febri-i/resurrect.nvim'
}

```

# Config

Using setup function

```lua
require("resurrect").setup({
    session_dir = "<put your session directory her, default = ~/.vimsession/>",
    auto_wipeout = true -- automatically do :bufdo bwipeout before loading session
})
```
Or
```lua
vim.g.RessurectSessionDir = "<session dir, default = ~/.Vimsession/>"
vim.g.RessurectAutoWipeout = true
```

# Usage
Combine it whatever you want the api is simple.
```lua
require("ressurect").save("session_name_here")
require("ressurect").load("session_name_here")
```
