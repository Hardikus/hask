{-# LANGUAGE GADTs #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# OPTIONS_GHC -Wall #-}
--------------------------------------------------------------------
-- |
-- Copyright :  (c) Edward Kmett 2014
-- License   :  BSD3
-- Maintainer:  Edward Kmett <ekmett@gmail.com>
-- Stability :  experimental
-- Portability: non-portable
--
--------------------------------------------------------------------
module Hask.End where

import Hask.Core
import GHC.Exts (Any)
import Unsafe.Coerce (unsafeCoerce)

-- * Ends

class hom ~ Hom => Ended (hom :: j -> j -> *) | j -> hom where
  type End :: (i -> i -> j) -> j
  end :: End p `hom` p a a

newtype End1 f = End { getEnd :: forall x. f x x }

instance Functor End1 where
  fmap f (End fcc) = End $ transport2 f fcc

instance Ended (->) where
  type End = End1
  end = getEnd

newtype End2 f y = End2 { getEnd2 :: forall x. f x x y }

instance Functor End2 where
  fmap f = Nat $ \(End2 fcc) -> End2 $ transport3 f fcc

-- instance Post (Post Functor) f => Functor (End2 f) where

instance Ended (Nat :: (i -> *) -> (i -> *) -> *) where
  type End = End2
  end = Nat getEnd2

class EndC (p :: i -> i -> Constraint) where
  endDict :: Dict (p a a)

instance p Any Any => EndC (p :: i -> i -> Constraint) where
  endDict = case unsafeCoerce (id :: p Any Any :- p Any Any) :: p Any Any :- p a a of
    Sub d -> d

instance Functor EndC where
  fmap f = dimap (Sub endDict) (Sub Dict) (runAny f) where
    runAny :: (p ~> q) -> p Any Any ~> q Any Any
    runAny = transport2

instance Ended (:-) where
  type End = EndC
  end = Sub endDict

-- * Coends

class hom ~ Hom => Coended (hom :: j -> j -> *) | j -> hom where
  type Coend :: (i -> i -> j) -> j
  coend :: p a a `hom` Coend p

data Coend1 f where
  Coend :: f x x -> Coend1 f

instance Coended (->) where
  type Coend = Coend1
  coend = Coend

instance Functor Coend1 where
  fmap f (Coend fcc) = Coend $ transport2 f fcc

data Coend2 f y where
  Coend2 :: f x x y -> Coend2 f y

instance Coended (Nat :: (i -> *) -> (i -> *) -> *) where
  type Coend = Coend2
  coend = Nat Coend2

instance Functor Coend2 where
  fmap f = Nat $ \(Coend2 fcc) -> Coend2 $ transport3 f fcc
