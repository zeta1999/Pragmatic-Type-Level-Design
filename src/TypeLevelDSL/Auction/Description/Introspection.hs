{-# LANGUAGE DataKinds                #-}
{-# LANGUAGE TypeOperators            #-}
{-# LANGUAGE FunctionalDependencies   #-}
{-# LANGUAGE TypeFamilies             #-}
{-# LANGUAGE PolyKinds                #-}
{-# LANGUAGE KindSignatures           #-}
{-# LANGUAGE ScopedTypeVariables      #-}

-- Variable ‘aType’ occurs more often
        -- in the constraint ‘Eval AsType aType String’
        -- than in the instance head ‘Eval AsInfo b ()’
{-# LANGUAGE UndecidableInstances     #-}

-- instance (Eval AsEngine engine (), Eval AsLots parts ()) =>
--          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
{-# LANGUAGE FlexibleContexts         #-}

-- instance (b ~ Parts a, Eval AsLots a ()) => Eval AsLots b ()
--                                             ^^^^^^^^^^^^^^^^
{-# LANGUAGE FlexibleInstances        #-}

module TypeLevelDSL.Auction.Description.Introspection where

import Data.Proxy (Proxy(..))
import GHC.TypeLits (KnownSymbol, symbolVal)

import TypeLevelDSL.Auction.Description.Language
import TypeLevelDSL.Eval


-- Interpretation tags

data AsInfo = AsInfo
data AsLots = AsLots
data AsLot = AsLot
data AsCensorship = AsCensorship
data AsCurrency = AsCurrency
data AsMoneyConst = AsMoneyConst
data AsLotPayload = AsLotPayload
data AsBid = AsBid
data AsMinBid = AsMinBid


-- Interpreting of the auction info (auctionInfo :: AuctionInfoTag)

instance (ai ~ MkAuctionInfo i, Eval AsInfo i [String]) =>
  Eval AsInfo ai [String] where
  eval _ _ = eval AsInfo (Proxy :: Proxy i)

instance (KnownSymbol name, KnownSymbol holder) =>
  Eval AsInfo (Info' name holder) [String] where
  eval _ _ = do
    pure $ ( "Name: " <> symbolVal (Proxy :: Proxy name) )
         : ( "Holder: " <> symbolVal (Proxy :: Proxy holder) )
         : []

-- Interpreting of the list of lots (lots :: LotsTag a)

-- No instance for an empty list. Empty lists are prohibited.
-- instance Eval AsLots '[] [String] where
--   eval _ _ = pure []

-- N.B., item is interpreted AsLot
instance Eval AsLot p [String] =>
  Eval AsLots (p ': '[]) [String] where
  eval _ _ = eval AsLot (Proxy :: Proxy p)

-- N.B., item is interpreted AsLot
instance (Eval AsLot p [String], Eval AsLots (x ': ps) [String]) =>
  Eval AsLots (p ': x ': ps) [String] where
  eval _ _ = do
    strs1 <- eval AsLot (Proxy :: Proxy p)
    strs2 <- eval AsLots (Proxy :: Proxy (x ': ps))
    pure $ strs1 <> strs2

instance (b ~ MkLots a, Eval AsLots a [String]) =>
  Eval AsLots b [String] where
  eval _ _ = eval AsLots (Proxy :: Proxy a)


-- Interpreting of a Lot

instance
  ( Eval AsCurrency currency [String]
  , Eval AsCensorship censorship [String]
  , Eval AsLotPayload payload String
  , KnownSymbol name
  , KnownSymbol descr
  ) =>
  Eval AsLot (Lot' name descr payload currency censorship) [String] where
  eval _ _ = do
    payload    <- eval AsLotPayload (Proxy :: Proxy payload)
    censorship <- eval AsCensorship (Proxy :: Proxy censorship)
    currency   <- eval AsCurrency (Proxy :: Proxy currency)
    pure $ ( "Lot: " <> symbolVal (Proxy :: Proxy name) )
         : ( "Description: " <> symbolVal (Proxy :: Proxy descr) )
         :   payload
         : ( currency <> censorship )


-- Interpreting of the Currency extension

instance (b ~ MkCurrency a, Eval AsCurrency a [String]) =>
  Eval AsCurrency b [String] where
  eval _ _ = eval AsCurrency (Proxy :: Proxy a)


-- Interpreting of the Censorship extension

instance (b ~ MkCensorship a, Eval AsCensorship a [String]) =>
  Eval AsCensorship b [String] where
  eval _ _ = eval AsCensorship (Proxy :: Proxy a)


-- Interpretating of the NoCensorship

instance Eval AsCensorship NoCensorship' [String] where
  eval _ _ = pure []


-- Interpreting a MoneyConst value

instance (b ~ MkMoneyConst a, Eval AsMoneyConst a String) =>
  Eval AsMoneyConst b String where
  eval _ _ = eval AsMoneyConst (Proxy :: Proxy a)

instance KnownSymbol val =>
 Eval AsMoneyConst (MoneyVal' val) String where
  eval _ _ = pure $ symbolVal (Proxy :: Proxy val)

-- Interpreting a LotPayload value

instance (b ~ MkLotPayload a, Eval AsLotPayload a String) =>
  Eval AsLotPayload b String where
  eval _ _ = eval AsLotPayload (Proxy :: Proxy a)