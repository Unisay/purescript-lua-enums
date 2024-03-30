let upstream-ps =
      https://github.com/purescript/package-sets/releases/download/psc-0.15.15-20240320/packages.dhall
        sha256:ae8a25645e81ff979beb397a21e5d272fae7c9ebdb021a96b1b431388c8f3c34

let upstream-lua =
      https://github.com/Unisay/purescript-lua-package-sets/releases/download/psc-0.15.15-20240339/packages.dhall
        sha256:cffab7593f608db869a010723c052eec77c9f02c0379a7785dbd572bc8376ef6

in  upstream-ps // upstream-lua
