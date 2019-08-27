{-# OPTIONS_GHC -Wall #-}

module Renamer where

import Control.Monad.State.Lazy

import CommonTypes
import qualified RawSyntax as Raw
import Syntax

-- | Convert a raw syntax type to a NeColus type.
rnType :: Raw.Type -> Type
rnType Raw.TyNat         = TyNat
rnType Raw.TyTop         = TyTop
rnType (Raw.TyArr t1 t2) = TyArr (rnType t1) (rnType t2)
rnType (Raw.TyIs t1 t2)  = TyIs (rnType t1) (rnType t2)
rnType (Raw.TyRec l t)   = TyRec l (rnType t)

-- | A stack for storing raw - NeColus variable assignments.
data RnEnv = EmptyRnEnv
           | SnocRnEnv RnEnv Raw.RawVariable Variable

-- | Get the NeColus variable for a raw variable in a stack.
rnLookup :: Raw.RawVariable -> RnEnv -> Maybe Variable
rnLookup _ EmptyRnEnv = Nothing
rnLookup v (SnocRnEnv env v' x)
  | Raw.eqRawVariable v v' = Just x
  | otherwise              = rnLookup v env

-- | Covert a full expression from raw syntax to NeColus syntax
-- given an initial stack and state.
rnFullExpr :: RnEnv -> Integer -> Raw.Expression -> (Expression, Integer)
rnFullExpr env state0 ex = runState (rnExpr env ex) state0

-- | Convert a raw expression to NeColus syntax.
rnExpr :: RnEnv -> Raw.Expression -> RnM Expression
rnExpr _ (Raw.ExLit i) = return (ExLit i)
rnExpr _ Raw.ExTop     = return ExTop
rnExpr env (Raw.ExVar x) = case rnLookup x env of
  Nothing -> error $ "Unbound variable " ++ show x -- fail miserably here
  Just y  -> return (ExVar y)

rnExpr env (Raw.ExAbs x e) = do
  y  <- freshVar
  e' <- rnExpr (SnocRnEnv env x y) e
  return (ExAbs y e')

rnExpr env (Raw.ExApp e1 e2) = do
  e1' <- rnExpr env e1
  e2' <- rnExpr env e2
  return (ExApp e1' e2')

rnExpr env (Raw.ExMerge e1 e2) = do
  e1' <- rnExpr env e1
  e2' <- rnExpr env e2
  return (ExMerge e1' e2')

rnExpr env (Raw.ExAnn e t) = do
  e' <- rnExpr env e
  return (ExAnn e' (rnType t))

rnExpr env (Raw.ExRec l e) = do
  e' <- rnExpr env e
  return (ExRec l e')

rnExpr env (Raw.ExRecFld e l) = do
  e' <- rnExpr env e
  return (ExRecFld e' l)
