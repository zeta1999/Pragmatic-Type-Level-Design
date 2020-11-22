{-# LANGUAGE DataKinds                #-}
{-# LANGUAGE TypeOperators            #-}
{-# LANGUAGE FunctionalDependencies   #-}
{-# LANGUAGE TypeFamilies             #-}
{-# LANGUAGE PolyKinds                #-}
{-# LANGUAGE KindSignatures           #-}
{-# LANGUAGE FlexibleContexts         #-}
{-# LANGUAGE FlexibleInstances        #-}
{-# LANGUAGE ScopedTypeVariables      #-}

module TypeLevelDSL.Auction.AuctionSpec where

import TypeLevelDSL.Auction.Language
import TypeLevelDSL.Auction.Exts
import TypeLevelDSL.Auction.AuctionDSL
import TypeLevelDSL.Auction.Implementation
import TypeLevelDSL.Auction.ExtsImpl
import TypeLevelDSL.Auction.AuctionDSLImpl
import TypeLevelDSL.Eval

import Test.Hspec

import Data.List (intercalate)
import Data.Proxy (Proxy(..))
import GHC.TypeLits (KnownSymbol, Symbol, KnownNat, Nat, symbolVal)


-- Test sample

type UKOnly  = Censorship (AllowedCountries "UK only" '[UK])
type UKAndUS = Censorship (AllowedCountries "UK & US" '[UK, US])

type PayloadLot1 = LotPayload (Payload (MoneyVal "1000.0"))
type PayloadLot2 = LotPayload (Payload (MoneyDynVal "202 min bid"))
type PayloadLot3 = LotPayload (Payload (MoneyVal "40000.0"))

type WorldArtsAuction = Auction
  ( Info "World arts" EnglishAuction "UK Bank")
  ( Lots '[ Lot "101" "Dali artwork"      PayloadLot1 (Currency GBP) UKOnly
          , Lot "202" "Chinese vase"      PayloadLot2 (Currency USD) UKAndUS
          , Lot "303" "Ancient mechanism" PayloadLot3 (Currency USD) NoCensorship
          ]
  )


type EnglishAuctionFlow = AuctionFlow
  ( LotProcess
      ( Action (GetPayloadValue "minBid" Print)
        ( Action (GetPayloadValue "minBid" Drop)
          End
        )
      )
  )


runner :: IO [String]
runner = do
  eval AsAction (Proxy :: Proxy End')               -- we can eval a 'data' type
  eval AsAction (Proxy :: Proxy End)                -- we can eval this as (act ~ MkAction act2, Eval AsAction act2 ())
  eval AsAuction (Proxy :: Proxy WorldArtsAuction)



spec :: Spec
spec =
  describe "Type level Servant-like eDSL Auction" $ do
    it "Run WorldArtsAuction script" $ do
      strs <- runner
      -- putStrLn $ intercalate "\n" strs
      strs `shouldBe`
        [ "==> Auction! <=="
        , "Name: World arts"
        , "Holder: UK Bank"
        , "Type: EnglishAuction"
        , "Lot: 101"
        , "Description: Dali artwork"
        , "Minimum bid: 1000.0"
        , "Currency: GBP"
        , "Eligible participants: UK"
        , "Lot: 202"
        , "Description: Chinese vase"
        , "Minimum bid: 20000.0"
        , "Currency: USD"
        , "Eligible participants: UK, US"
        , "Lot: 303"
        , "Description: Ancient mechanism"
        , "Minimum bid: 40000.0"
        , "Currency: USD"
        ]