-- Implicit CAD. Copyright (C) 2011, Christopher Olah (chris@colah.ca)
-- Copyright (C) 2014 2015 2016, Julia Longtin (julial@turinglace.com)
-- Released under the GNU AGPLV3+, see LICENSE

-- allow us to specify what package to import what module from.
-- We don't actually care, but when we compile our haskell examples, we do.
{-# LANGUAGE PackageImports #-}

-- An executor, which parses openscad code, and executes it.
module Graphics.Implicit.ExtOpenScad (runOpenscad) where

import Prelude(String, IO, ($), pure, (<$>), either, (.))

import Graphics.Implicit.Definitions (SymbolicObj2, SymbolicObj3)

import Graphics.Implicit.ExtOpenScad.Definitions (VarLookup, ScadOpts, Message(Message), MessageType(SyntaxError), CompState(CompState, oVals, varLookup, messages))

import Graphics.Implicit.ExtOpenScad.Parser.Statement (parseProgram)

import Graphics.Implicit.ExtOpenScad.Parser.Util (sourcePosition)

import Graphics.Implicit.ExtOpenScad.Eval.Statement (runStatementI)

import Graphics.Implicit.ExtOpenScad.Eval.Constant (addConstants)

import Graphics.Implicit.ExtOpenScad.Util.OVal (divideObjs)

import Text.Parsec.Error (errorPos, errorMessages, showErrorMessages)

import "monads-tf" Control.Monad.State.Lazy (runStateT)

import System.Directory (getCurrentDirectory)

import Data.Foldable (traverse_)

-- | Small wrapper of our parser to handle parse errors, etc.
runOpenscad :: ScadOpts -> [String] -> String -> IO (VarLookup, [SymbolicObj2], [SymbolicObj3], [Message])
runOpenscad scadOpts constants source = do
      (initialObjects, initialMessages) <- addConstants constants
      let err e = pure (initialObjects, [], [], mesg e : initialMessages)
          run sts = rearrange <$> do
            let sts' = traverse_ runStatementI sts
            path <- getCurrentDirectory
            runStateT sts' $ CompState initialObjects [] path initialMessages scadOpts
      either err run $ parseProgram "" source
  where
    rearrange (_, s) =
      let (obj2s, obj3s, _) = divideObjs $ oVals s
      in (varLookup s, obj2s, obj3s, messages s)
    show' = showErrorMessages "or" "unknown parse error" "expecting" "unexpected" "end of input" . errorMessages
    mesg e = Message SyntaxError (sourcePosition $ errorPos e) $ show' e
