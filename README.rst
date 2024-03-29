flap.vim
========

flap.vim is a Vim plugin to extend ``CTRL-A`` and ``CTRL-X`` by user defined
rules.

.. image:: https://github.com/hattya/flap.vim/actions/workflows/ci.yml/badge.svg
   :target: https://github.com/hattya/flap.vim/actions/workflows/ci.yml

.. image:: https://ci.appveyor.com/api/projects/status/moypdj3upgoa051j/branch/master?svg=true
   :target: https://ci.appveyor.com/project/hattya/flap-vim

.. image:: https://codecov.io/gh/hattya/flap.vim/branch/master/graph/badge.svg
   :target: https://codecov.io/gh/hattya/flap.vim

.. image:: https://img.shields.io/badge/doc-:h%20flap.txt-blue.svg
   :target: doc/flap.txt


Installation
------------

Vundle_

.. code:: vim

   Plugin 'hattya/flap.vim'

vim-plug_

.. code:: vim

   Plug 'hattya/flap.vim'

dein.vim_

.. code:: vim

   call dein#add('hattya/flap.vim')

.. _Vundle: https://github.com/VundleVim/Vundle.vim
.. _vim-plug: https://github.com/junegunn/vim-plug
.. _dein.vim: https://github.com/Shougo/dein.vim


Requirements
------------

- Vim 8.0+
- repeat.vim

  - `kana/vim-repeat`_
  - `tpope/vim-repeat`_

.. _kana/vim-repeat: https://github.com/kana/vim-repeat
.. _tpope/vim-repeat: https://github.com/tpope/vim-repeat


Usage
-----

.. code:: vim

   nmap  <C-A> <Plug>(flap-inc)
   vmap  <C-A> <Plug>(flap-inc)
   vmap g<C-A> <Plug>(flap-inc-g)

   nmap  <C-X> <Plug>(flap-dec)
   vmap  <C-X> <Plug>(flap-dec)
   vmap g<C-X> <Plug>(flap-dec-g)


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
