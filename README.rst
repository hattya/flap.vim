flap.vim
========

flap.vim is a Vim plugin to extend ``CTRL-A`` and ``CTRL-X`` by user defined
rules.


Installation
------------

pathogen.vim_

.. code:: console

   $ cd ~/.vim/bundle
   $ git clone https://github.com/hattya/flap.vim

Vundle_

.. code:: vim

   Plugin 'hattya/flap.vim'

vim-plug_

.. code:: vim

   Plug 'hattya/flap.vim'

dein.vim_

.. code:: vim

   call dein#add('hattya/flap.vim')

.. _pathogen.vim: https://github.com/tpope/vim-pathogen
.. _Vundle: https://github.com/VundleVim/Vundle.vim
.. _vim-plug: https://github.com/junegunn/vim-plug
.. _dein.vim: https://github.com/Shougo/dein.vim


Usage
-----

.. code:: vim

   nmap <C-A> <Plug>(flap-inc)
   vmap <C-A> <Plug>(flap-inc)

   nmap <C-X> <Plug>(flap-dec)
   vmap <C-X> <Plug>(flap-dec)


Testing
-------

flap.vim uses themis.vim_ for testing.

.. code:: console

   $ cd /path/to/flap.vim
   $ git clone https://github.com/thinca/vim-themis
   $ ./vim-themis/bin/themis

.. _themis.vim: https://github.com/thinca/vim-themis


License
-------

flap.vim is distributed under the terms of the MIT License.
