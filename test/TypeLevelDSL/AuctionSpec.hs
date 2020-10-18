{-# LANGUAGE DataKinds                #-}
{-# LANGUAGE TypeOperators            #-}
{-# LANGUAGE FunctionalDependencies   #-}
{-# LANGUAGE TypeFamilies             #-}
{-# LANGUAGE PolyKinds                #-}
{-# LANGUAGE KindSignatures           #-}
{-# LANGUAGE FlexibleContexts         #-}
{-# LANGUAGE FlexibleInstances        #-}
{-# LANGUAGE ScopedTypeVariables      #-}

module TypeLevelDSL.AuctionSpec where

import TypeLevelDSL.Auction.Language
import TypeLevelDSL.Auction.Implementation
import TypeLevelDSL.Eval

import           Test.Hspec

import Data.Proxy (Proxy(..))
import GHC.TypeLits (KnownSymbol, Symbol, symbolVal)

-- User space

data USD
data EUR
data GBP

data AllowedCountries (name :: Symbol) (participants :: [ Country ])

class CurrencyInfo a where
  toString :: Proxy a -> String

instance CurrencyInfo USD where toString _ = "USD"
instance CurrencyInfo EUR where toString _ = "EUR"
instance CurrencyInfo GBP where toString _ = "GBP"


-- Implementation

-- Interpreting of the participants list

data AsParticipants = AsParticipants

-- Empty list of participants is not allowed.
-- instance Currency p => Eval AsParticipants '[] [String] where
--   eval _ _ = pure []

instance CurrencyInfo p => Eval AsParticipants (p ': '[]) [String] where
  eval _ _ = pure [toString (Proxy :: Proxy p)]

instance (CurrencyInfo p, Eval AsParticipants (x ': xs) [String]) =>
  Eval AsParticipants (p ': x ': xs) [String] where
  eval _ _ = do
    ps <- eval AsParticipants (Proxy :: Proxy (x ': xs))
    let p = toString (Proxy :: Proxy p)
    pure $ p : ps


-- Interpreting of the AllowedCountries censorship

instance (Eval AsParticipants participants String) =>
  Eval AsCensorship (AllowedCountries name participants) () where
  eval _ _ = do
    participants <- eval AsParticipants (Proxy :: Proxy participants)
    putStrLn $ "Eligible participants: " <> participants


-- Interpreting of the currency (currency :: CurrencyTag a)


-- Test sample

type UKOnly = Censorship (AllowedCountries "UK only" '[UK])
type UKAndUS = Censorship (AllowedCountries "UK only" '[UK, US])
type Info1 = AuctionInfo (Info "UK Art" EnglishAuction "UK Bank")
type Lot1 = Lot "101" "Dali artwork" (Currency GBP) UKOnly
type Lot2 = Lot "202" "Chinesse vase" (Currency USD) UKAndUS
type Lot3 = Lot "303" "Ancient mechanism" (Currency USD) NoCensorship
type Auction1 = Auction Info1 (Lots '[Lot1, Lot2, Lot3])


runner :: IO ()
runner = pure ()


spec :: Spec
spec =
  describe "Type level Servant-like eDSL Auction" $ do
    it "Run Auction script" $ do
      runner
