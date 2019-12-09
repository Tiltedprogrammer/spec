{-# LANGUAGE ExtendedDefaultRules, NoMonoPatBinds #-}
module Main(main) where
import Data.Time.Clock.POSIX (getPOSIXTime)
{-data List a = Nil | Cons a (List a)-}

data Char' = A | B

--data Maybe a = Just a | Nothing


-- | A class of types that can be fully evaluated.
class NFData a where
    rnf :: a -> ()
    rnf a = a `seq` ()

instance NFData Int 
instance NFData Integer
instance NFData Float
instance NFData Double

instance NFData Char
instance NFData Bool
instance NFData ()

instance NFData a => NFData (Maybe a) where
    rnf Nothing  = ()
    rnf (Just x) = rnf x

instance (NFData a, NFData b) => NFData (Either a b) where
    rnf (Left x)  = rnf x
    rnf (Right y) = rnf y

instance NFData a => NFData [a] where
    rnf [] = ()
    rnf (x:xs) = rnf x `seq` rnf xs

instance (NFData a, NFData b) => NFData (a,b) where
  rnf (x,y) = rnf x `seq` rnf y

time_ :: IO a -> IO Double
time_ act = do { start <- getTime; act; end <- getTime; return $! (Prelude.-) end start }

getTime :: IO Double
getTime = (fromRational . toRational) `fmap` getPOSIXTime

main = do { t <- time_ (rnf results `seq` return ()); print t }
  where results = map assertEq tests

assertEq :: (Show a, Eq a) => (a, a) -> ()
assertEq (x, y) = if x == y then () else error ("FAIL! " ++ show x ++ ", " ++ show y)

root = let
         wCons_a33 = \x1 -> \x2 -> (:) x1 x2
         wA_a32 = A
         wB_a41 = B
         wFalse_a51 = False
         wJust_a52 = \x1 -> Just x1
         wNothing_a53 = Nothing
         wTrue_a54 = True
         wNil_a34 = []
         eq = \a -> \b -> case a of
                            A ->
                              case b of
                                A -> wTrue_a54
                                _ -> wFalse_a51
                            B ->
                              case b of
                                B -> wTrue_a54
                                _ -> wFalse_a51
         eql = \ys -> \xs -> case ys of
                               [] ->
                                 case xs of
                                   [] -> wTrue_a54
                                   _ -> wFalse_a51
                               (:) u us ->
                                 case xs of
                                   [] -> wFalse_a51
                                   (:) w ws ->
                                     case eq u w of
                                       True -> eql us ws
                                       False -> wFalse_a51
                                   _ -> wFalse_a51
         last = \xs -> case xs of
                         (:) y ys ->
                           case ys of
                             [] -> y
                             _ -> last ys
         init = \xs -> case xs of
                         (:) u us ->
                           case us of
                             [] -> wNil_a34
                             _ ->
                               let awCons2_a76 = init us
                               in wCons_a33 u awCons2_a76
         head = \xs -> case xs of (:) y ys -> y
         tail = \xs -> case xs of (:) y ys -> ys
         append = \xs -> \ys -> case xs of
                                  [] -> ys
                                  (:) u us ->
                                    let awCons2_a65 = append us ys
                                    in wCons_a33 u awCons2_a65
         rest = \p -> \s -> case p of
                              [] -> wNothing_a53
                              _ ->
                                case s of
                                  [] -> wJust_a52 p
                                  _ ->
                                    let
                                      aeq1_a78 = head p
                                      aeq2_a77 = head s
                                      arest1_a80 = tail p
                                      arest2_a79 = tail s
                                    in case eq aeq1_a78 aeq2_a77 of
                                         True -> rest arest1_a80 arest2_a79
                                         False -> wNothing_a53
         ams = \p -> \s -> \a -> case p of
                                   [] -> wNil_a34
                                   _ ->
                                     let
                                       np = let arest1_a66 = head p
                                            in rest arest1_a66 s
                                     in case np of
                                          Nothing ->
                                            let aams1_a67 = tail p
                                            in ams aams1_a67 s a
                                          Just xs ->
                                            case xs of
                                              (:) u us ->
                                                let
                                                  aappend2_a68 = wCons_a33 u wNil_a34
                                                  aams1_a69 = tail p
                                                in case eq u a of
                                                     True -> append s aappend2_a68
                                                     False -> ams aams1_a69 s a
         failf = \p -> \s -> case tail s of
                               [] -> wNil_a34
                               _ ->
                                 let
                                   ns = let afailf2_a70 = init s
                                        in failf p afailf2_a70
                                   nsl = let aams3_a71 = last s
                                         in ams p ns aams3_a71
                                 in case eql nsl wNil_a34 of
                                      True ->
                                        case eql ns wNil_a34 of
                                          True -> wNil_a34
                                          False ->
                                            let
                                              f = failf p ns
                                              aams3_a72 = last s
                                            in ams p f aams3_a72
                                      False -> nsl
         inout = \p -> \s -> case p of
                               [] -> wNil_a34
                               _ ->
                                 let
                                   aeql1_a81 = head p
                                   ainout1_a82 = tail p
                                 in case eql aeql1_a81 s of
                                      True -> head p
                                      False -> inout ainout1_a82 s
         out = \p -> \s -> case s of
                             [] -> wNil_a34
                             _ ->
                               let o = inout p s
                               in case o of
                                    (:) x xs ->
                                      let
                                        aout2_a74 = failf p s
                                        awCons2_a73 = out p aout2_a74
                                      in wCons_a33 o awCons2_a73
                                    _ ->
                                      let aout2_a75 = failf p s
                                      in out p aout2_a75
         loop = \p -> \s -> \t -> \o -> case t of
                                          [] -> o
                                          _ ->
                                            let
                                              ns = let aams3_a56 = head t
                                                   in ams p s aams3_a56
                                            in case ns of
                                                 (:) x xs ->
                                                   let
                                                     aloop3_a58 = tail t
                                                     aappend2_a59 = out p ns
                                                     aloop4_a57 = append o aappend2_a59
                                                   in loop p ns aloop3_a58 aloop4_a57
                                                 _ ->
                                                   case s of
                                                     [] ->
                                                       let aloop3_a60 = tail t
                                                       in loop p wNil_a34 aloop3_a60 o
                                                     _ ->
                                                       let aloop2_a61 = failf p s
                                                       in loop p aloop2_a61 t o
         pats = let
                  awCons1_a62 = wCons_a33 wB_a41 wNil_a34
                  awCons1_a63 = wCons_a33 wA_a32 wNil_a34
                  awCons2_a64 = wCons_a33 awCons1_a62 wNil_a34
                in wCons_a33 awCons1_a63 awCons2_a64
         root = let
                  awCons2_a40 = wCons_a33 wA_a32 wNil_a34
                  awCons2_a43 = wCons_a33 wA_a32 awCons2_a40
                  awCons2_a45 = wCons_a33 wB_a41 awCons2_a43
                  aloop3_a47 = wCons_a33 wA_a32 awCons2_a45
                in loop pats wNil_a34 aloop3_a47 wNil_a34
       in root
tests = let
          wTup2_a50 = \x1 -> \x2 -> (,) x1 x2
          wCons_a33 = \x1 -> \x2 -> (:) x1 x2
          wNil_a34 = []
          w1_a55 = 1 :: Int
          tests = let awCons1_a84 = wTup2_a50 w1_a55 w1_a55
                  in wCons_a33 awCons1_a84 wNil_a34
        in tests

{-
/tmp/Main2021 +RTS -t 
<<ghc: 112680 bytes, 1 GCs, 36080/36080 avg/max bytes residency (1 samples), 1M in use, 0.00 INIT (0.00 elapsed), 0.00 MUT (0.00 elapsed), 0.00 GC (0.00 elapsed) :ghc>>

-}
