# nvim-jupytext

Edit Jupyter Notebooks alongside their plain‑text counterparts, with zero friction.

Under the hood it uses [jupytext](https://github.com/mwouts/jupytext) to handle conversions.

This plugin is inspired by
[GCBallesteros/jupytext.vim](https://github.com/GCBallesteros/jupytex.nvim),
but never writes intermediary files into your project folder.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "nvim-contrib/nvim-jupytext",
  config = true,
}
```
