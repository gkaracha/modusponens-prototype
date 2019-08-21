{-# OPTIONS_GHC -Wall #-}

module PrettyPrinter where

import Text.PrettyPrint

arrow :: Doc
arrow = text "→"

dot :: Doc
dot = text "."

commaSep :: [Doc] -> [Doc]
commaSep = punctuate comma

parensList :: [Doc] -> Doc
parensList = parens . hsep . commaSep

class PrettyPrint a where
  ppr :: a -> Doc

class PrettyPrintList a where
  pprList :: [a] -> Doc

instance PrettyPrintList Char where
  pprList = text

instance PrettyPrintList a => PrettyPrint [a] where
  ppr = pprList

instance PrettyPrint Int where
  ppr = int