# Jujutsu diffsplit for NeoVim

Minimalistic attempt to reproduce `:G[v]d[iffsplit]` from Tim Pope's vim-fugitive.
If not provided, the diffed revision is `@-`.

    :Jd[iffsplit]  [<rev>]
    :Jvd[iffsplit] [<rev>]

The resulting buffer is opened in a temporary workspace containing only that file,
and restored as is onto the revision upon buffer write; descendants are not
rebased.

The workflow is as follows:

- with vim-fugitive, the basic workflow is to integrate changes from the working
  copy into the index to commit changed progressively

- with Jujutsu you can prepend an empty change (`jj new --no-edit -B @`) and then
  integrate content from the working copy with `:Gvd @-`.

## Installing

Add this (somewhere):

    {
    	"trosh/Jdiffsplit.nvim",
    	config = function()
    		require("Jdiffsplit").setup()
    	end,
    },
