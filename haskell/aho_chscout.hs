-- Code: 45940e4e93b97a5bb6137538e68a8fd58194dc69
-- Run: noassertions

{-# LANGUAGE ExtendedDefaultRules, NoMonoPatBinds #-}
module Main(main) where
import Data.Time.Clock.POSIX (getPOSIXTime)
{-data List a = Nil | Cons a (List a)-}

data Char' = A | B deriving(Show)

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
         h0 = let
                wA_u87 = h10
                eq_u102 = h67
                aams3_u509 = h89
              in case eq_u102 wA_u87 aams3_u509 of
                   True -> h1
                   False -> h73
         h1 = let
                eq_u102 = h67
                aeq2_u601 = h72
                aeq1_u602 = h72
              in case eq_u102 aeq1_u602 aeq2_u601 of
                   True -> h2
                   False -> h66
         h2 = let
                np_u700 = rest_u116 arest1_u702 ns_u678
                rest_u116 = h47
                ns_u678 = h9
                arest1_u702 = h8
              in h3 np_u700
         h3 = \np_u700 -> case np_u700 of
                            Nothing -> h4
                            Just xs_u724 -> h22 xs_u724
         h4 = let
                aloop4_u694 = append_u114 aloop4_u590 aappend2_u691
                append_u114 = h15
                aloop4_u590 = h21
                aappend2_u691 = h7
              in h5 aloop4_u694
         h5 = \aloop4_u694 -> case aloop4_u694 of
                                [] -> h6
                                (:) u_u786 us_u788 -> h13 u_u786 us_u788
         h6 = let aappend2_u755 = h7
              in aappend2_u755
         h7 = let
                o_u770 = h8
                awCons2_u777 = h12
              in (:) o_u770 awCons2_u777
         h8 = let arest1_u298 = h9
              in arest1_u298
         h9 = let
                wA_u87 = h10
                wNil_u100 = h11
              in (:) wA_u87 wNil_u100
         h10 = A
         h11 = []
         h12 = let wNil_u100 = h11
               in wNil_u100
         h13 = \u_u786 -> \us_u788 -> let awCons2_u790 = h14 us_u788
                                      in (:) u_u786 awCons2_u790
         h14 = \us_u788 -> case us_u788 of
                             [] -> h6
                             (:) u_u816 us_u818 -> h13 u_u816 us_u818
         h15 = \xs_u841 -> h16 xs_u841
         h16 = \xs_u841 -> \ys_u843 -> h17 xs_u841 ys_u843
         h17 = \xs_u841 -> \ys_u843 -> case xs_u841 of
                                         [] -> h18 ys_u843
                                         (:) u_u847 us_u849 -> h19 ys_u843 u_u847 us_u849
         h18 = \ys_u843 -> ys_u843
         h19 = \ys_u843 -> \u_u847 -> \us_u849 -> let
                                                    awCons2_u813 = h20 ys_u843 us_u849
                                                  in (:) u_u847 awCons2_u813
         h20 = \ys_u843 -> \us_u849 -> case us_u849 of
                                         [] -> h18 ys_u843
                                         (:) u_u856 us_u858 -> h19 ys_u843 u_u856 us_u858
         h21 = let
                 o_u840 = h8
                 awCons2_u844 = h6
               in (:) o_u840 awCons2_u844
         h22 = \xs_u724 -> case xs_u724 of (:) u_u868 us_u870 -> h23 u_u868
         h23 = \u_u868 -> case u_u868 of
                            A -> h24
                            B -> h46
         h24 = let
                 aloop4_u694 = append_u114 aloop4_u590 aappend2_u691
                 append_u114 = h15
                 aloop4_u590 = h21
                 aappend2_u691 = h7
               in h25 aloop4_u694
         h25 = \aloop4_u694 -> case aloop4_u694 of
                                 [] -> h26
                                 (:) u_u873 us_u875 -> h44 u_u873 us_u875
         h26 = let
                 eql_u104 = h30
                 ns_u696 = h43
                 aeql1_u756 = h8
               in case eql_u104 aeql1_u756 ns_u696 of
                    True -> h27
                    False -> h29
         h27 = let
                 o_u751 = h8
                 awCons2_u773 = h28
               in (:) o_u751 awCons2_u773
         h28 = let
                 o_u819 = h8
                 awCons2_u859 = h12
               in (:) o_u819 awCons2_u859
         h29 = let
                 o_u813 = h8
                 awCons2_u853 = h12
               in (:) o_u813 awCons2_u853
         h30 = \ys_u990 -> h31 ys_u990
         h31 = \ys_u990 -> \xs_u992 -> h32 ys_u990 xs_u992
         h32 = \ys_u990 -> \xs_u992 -> case ys_u990 of
                                         [] -> h33 xs_u992
                                         (:) u_u995 us_u997 -> h38 xs_u992 u_u995 us_u997
         h33 = \xs_u992 -> case xs_u992 of
                             [] -> h34
                             _ -> h36
         h34 = let wTrue_u98 = h35
               in wTrue_u98
         h35 = True
         h36 = let wFalse_u92 = h37
               in wFalse_u92
         h37 = False
         h38 = \xs_u992 -> \u_u995 -> \us_u997 -> case xs_u992 of
                                                    [] -> h36
                                                    (:) w_u786 ws_u788 -> h39 w_u786 ws_u788 u_u995 us_u997
                                                    _ -> h36
         h39 = \w_u786 -> \ws_u788 -> \u_u995 -> \us_u997 -> case u_u995 of
                                                               A -> h40 w_u786 ws_u788 us_u997
                                                               B -> h42 w_u786 ws_u788 us_u997
         h40 = \w_u786 -> \ws_u788 -> \us_u997 -> case w_u786 of
                                                    A -> h41 ws_u788 us_u997
                                                    _ -> h36
         h41 = \ws_u788 -> \us_u997 -> case us_u997 of
                                         [] -> h33 ws_u788
                                         (:) u_u1011 us_u1013 -> h38 ws_u788 u_u1011 us_u1013
         h42 = \w_u786 -> \ws_u788 -> \us_u997 -> case w_u786 of
                                                    B -> h41 ws_u788 us_u997
                                                    _ -> h36
         h43 = let
                 wA_u87 = h10
                 awCons2_u736 = h8
               in (:) wA_u87 awCons2_u736
         h44 = \u_u873 -> \us_u875 -> let awCons2_u751 = h45 us_u875
                                      in (:) u_u873 awCons2_u751
         h45 = \us_u875 -> case us_u875 of
                             [] -> h26
                             (:) u_u1017 us_u1019 -> h44 u_u1017 us_u1019
         h46 = let
                 aloop4_u694 = append_u114 aloop4_u590 aappend2_u691
                 append_u114 = h15
                 aloop4_u590 = h21
                 aappend2_u691 = h7
               in h5 aloop4_u694
         h47 = \p_u1022 -> h48 p_u1022
         h48 = \p_u1022 -> \s_u1024 -> h49 p_u1022 s_u1024
         h49 = \p_u1022 -> \s_u1024 -> case p_u1022 of
                                         [] -> h50
                                         _ -> h52 p_u1022 s_u1024
         h50 = let wNothing_u96 = h51
               in wNothing_u96
         h51 = Nothing
         h52 = \p_u1022 -> \s_u1024 -> case s_u1024 of
                                         [] -> h53 p_u1022
                                         _ -> h54 p_u1022 s_u1024
         h53 = \p_u1022 -> Just p_u1022
         h54 = \p_u1022 -> \s_u1024 -> case p_u1022 of
                                         (:) y_u1031 ys_u1030 -> h55 s_u1024 ys_u1030 y_u1031
         h55 = \s_u1024 -> \ys_u1030 -> \y_u1031 -> case y_u1031 of
                                                      A -> h56 s_u1024 ys_u1030
                                                      B -> h61 s_u1024 ys_u1030
         h56 = \s_u1024 -> \ys_u1030 -> case s_u1024 of
                                          (:) y_u1039 ys_u1041 -> h57 ys_u1030 y_u1039 ys_u1041
         h57 = \ys_u1030 -> \y_u1039 -> \ys_u1041 -> case y_u1039 of
                                                       A -> h58 ys_u1030 ys_u1041
                                                       _ -> h50
         h58 = \ys_u1030 -> \ys_u1041 -> let arest1_u740 = ys_u1030
                                         in h59 arest1_u740 ys_u1041
         h59 = \arest1_u740 -> \ys_u1041 -> case arest1_u740 of
                                              [] -> h50
                                              _ -> h60 arest1_u740 ys_u1041
         h60 = \arest1_u740 -> \ys_u1041 -> let arest2_u742 = ys_u1041
                                            in h52 arest1_u740 arest2_u742
         h61 = \s_u1024 -> \ys_u1030 -> case s_u1024 of
                                          (:) y_u1039 ys_u1041 -> h62 ys_u1030 y_u1039 ys_u1041
         h62 = \ys_u1030 -> \y_u1039 -> \ys_u1041 -> case y_u1039 of
                                                       B -> h63 ys_u1030 ys_u1041
                                                       _ -> h50
         h63 = \ys_u1030 -> \ys_u1041 -> let arest1_u740 = ys_u1030
                                         in h64 arest1_u740 ys_u1041
         h64 = \arest1_u740 -> \ys_u1041 -> case arest1_u740 of
                                              [] -> h50
                                              _ -> h65 arest1_u740 ys_u1041
         h65 = \arest1_u740 -> \ys_u1041 -> let arest2_u742 = ys_u1041
                                            in h52 arest1_u740 arest2_u742
         h66 = let
                 np_u700 = rest_u116 arest1_u702 ns_u678
                 rest_u116 = h47
                 ns_u678 = h9
                 arest1_u702 = h8
               in h3 np_u700
         h67 = \a_u1054 -> h68 a_u1054
         h68 = \a_u1054 -> \b_u1056 -> h69 a_u1054 b_u1056
         h69 = \a_u1054 -> \b_u1056 -> case a_u1054 of
                                         A -> h70 b_u1056
                                         B -> h71 b_u1056
         h70 = \b_u1056 -> case b_u1056 of
                             A -> h34
                             _ -> h36
         h71 = \b_u1056 -> case b_u1056 of
                             B -> h34
                             _ -> h36
         h72 = let wA_u87 = h10
               in wA_u87
         h73 = let
                 eq_u102 = h67
                 aeq1_u608 = h72
                 aeq2_u610 = h89
               in case eq_u102 aeq1_u608 aeq2_u610 of
                    True -> h74
                    False -> h88
         h74 = let
                 np_u698 = rest_u116 arest1_u700 ns_u676
                 rest_u116 = h47
                 ns_u676 = h9
                 arest1_u700 = h8
               in h75 np_u698
         h75 = \np_u698 -> case np_u698 of
                             Nothing -> h76
                             Just xs_u1061 -> h84 xs_u1061
         h76 = let
                 aloop4_u691 = append_u114 aloop4_u598 aappend2_u692
                 append_u114 = h15
                 aloop4_u598 = h77
                 aappend2_u692 = h7
               in h5 aloop4_u691
         h77 = let
                 awCons2_u861 = h78
                 o_u913 = h8
               in (:) o_u913 awCons2_u861
         h78 = let
                 eql_u104 = h30
                 ns_u507 = h82
                 aeql1_u956 = h8
               in case eql_u104 aeql1_u956 ns_u507 of
                    True -> h79
                    False -> h80
         h79 = let
                 o_u819 = h8
                 awCons2_u1062 = h12
               in (:) o_u819 awCons2_u1062
         h80 = let
                 o_u819 = h81
                 awCons2_u1066 = h12
               in (:) o_u819 awCons2_u1066
         h81 = let arest1_u467 = h82
               in arest1_u467
         h82 = let
                 wB_u90 = h83
                 wNil_u100 = h11
               in (:) wB_u90 wNil_u100
         h83 = B
         h84 = \xs_u1061 -> case xs_u1061 of
                              (:) u_u1078 us_u1080 -> h85 u_u1078
         h85 = \u_u1078 -> case u_u1078 of
                             A -> h86
                             B -> h87
         h86 = let
                 aloop4_u691 = append_u114 aloop4_u598 aappend2_u692
                 append_u114 = h15
                 aloop4_u598 = h77
                 aappend2_u692 = h7
               in h25 aloop4_u691
         h87 = let
                 aloop4_u691 = append_u114 aloop4_u598 aappend2_u692
                 append_u114 = h15
                 aloop4_u598 = h77
                 aappend2_u692 = h7
               in h5 aloop4_u691
         h88 = let
                 np_u698 = rest_u116 arest1_u700 ns_u676
                 rest_u116 = h47
                 ns_u676 = h9
                 arest1_u700 = h8
               in h75 np_u698
         h89 = let wB_u90 = h83
               in wB_u90
       in h0
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
<<ghc: 129568 bytes, 1 GCs, 36080/36080 avg/max bytes residency (1 samples), 1M in use, 0.00 INIT (0.00 elapsed), 0.00 MUT (0.00 elapsed), 0.00 GC (0.00 elapsed) :ghc>>

-}

