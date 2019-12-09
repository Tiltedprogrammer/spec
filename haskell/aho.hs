pats = ["he","she","his","hers"]

-- Example:
-- *Main> loop pats [] "shershe" []
-- ["she","he","hers","she","he"]
-- *Main> loop2 pats [] "shershe" []
-- ["she","he","hers","she","he"]



-- check whether s' is strict prefix of p
rest :: [Char] -> [Char] -> Maybe [Char]
rest [] s' = Nothing
rest p' [] = Just p'
rest p' s' 
      | (head p') == (head s') = rest (tail p') (tail s')
      | otherwise = Nothing

-- already matched string, i.e. in a sense prefix tree
ams :: [[Char]] -> [Char] -> Char -> [Char]
ams p s a 
    | (null p) = []
    | otherwise =  let np = rest (head p) s in
        case np of 
            Nothing -> ams (tail p) s a
            Just (x:xs) -> if x == a then (s ++ [x]) -- x == a dynamic condition, however s++[x] is fully static
                           else ams (tail p) s a


--inductively searches prefix-suffix
failf :: [[Char]] -> [Char] -> [Char]
{-failf p s 
    | tail s == [] = [] -- base, i.e. fail for ams of length 1 is root
    | otherwise = let ns = failf p (init s) --failf for previous ams
                      nsl = ams p ns (last s)   
                      in if nsl == [] then 
                            if ns == [] then [] -- have gone down to base case
                            else ams p (failf p ns) (last s) -- go down to failf for prev ams
                        else nsl
-}
failf p s = if (tail s == []) then []
            else  let ns = failf p (init s) --failf for previous ams
                      nsl = ams p ns (last s)   
                in if nsl == [] then 
                    if ns == [] then [] -- have gone down to base case
                    else ams p (failf p ns) (last s) -- go down to failf for prev ams
                   else nsl
                        --gather matches for ams among all patterns
out :: [[Char]] -> [Char] -> [[Char]]
out p s 
    | s == [] = []
    | otherwise =  let o = (out' p s) in
        case o of 
            (x:xs) -> o : (out p (failf p s))
            _      ->  (out p (failf p s)) 
            where
                out' [] _ = [] 
                out' p' s' =  if (head p') == s' then (head p')
                                else out' (tail p') s'  

--aho-corasick
loop _ _ [] o = o
loop p s t o = let ns = ams p s (head t) in
    case ns of 
        (x:xs) -> loop p ns (tail t) o ++ (out p ns)
        _      -> if s == [] then loop p [] (tail t) o
                  else loop p (failf p s) t o 


-- optimization from aho-corasick paper
f1 :: [[Char]] -> [Char] -> [Char]
f1 p s = let fs = failf p s
        in if fs == [] then [] --base
            else if (helper p s) then (f1 p fs) -- f1 = f1(failf s) if for all 'a' (ams (failf s) 'a') != [] => (ams s 'a') != [] 
                 else fs where
        helper [] _  = True
        helper p s = let ns = rest (head p) (failf p s)
                         h1 = helper (tail p) s in
                            case ns of
                                Nothing -> h1
                                Just x  -> if (ams p s (head x)) == [] then False
                                           else h1

-- optimization numba two, i.e. do goto after fail
d :: [[Char]] -> [Char] -> Char -> [Char]
d p [] a = (ams p [] a)
d p s a = let gk = (ams p s a) in
    case gk of
        [] -> d p (failf p s) a
        _  -> gk

loop2 _ _ [] o = o
loop2 p s t o = let ns = d p s (head t) in
    loop2 p ns (tail t) (o ++ (out p ns))  
