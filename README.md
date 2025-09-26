# My first NeoVim plugin

Minimalistic attempt to reproduce `:Gvdiffsplit` from Tim Pope's vim-fugitive.
If not provided, the diffed revision is `@-`.

    :Jd[iffsplit]  [<rev>]
    :Jvd[iffsplit] [<rev>]

The resulting buffer is read-only, but it is rather easy to work with alongside
Jujutsu, in my opinion. For example:

- with vim-fugitive, the basic workflow is to integrate changes from the working
  copy into the index to commit changed progressively

- but with Jujutsu you can easily prepend an empty change (`new -B @`) and then
  integrate content from the “working copy” by diffing against `@+`.
