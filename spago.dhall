{ name = "purescript-lua-enums"
, dependencies =
  [ "control"
  , "either"
  , "gen"
  , "maybe"
  , "newtype"
  , "nonempty"
  , "partial"
  , "prelude"
  , "tuples"
  , "unfoldable"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
}
