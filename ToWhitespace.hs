
{-# LANGUAGE ViewPatterns #-}


module ToWhitespace(
    map_to_whitespace,
    from_pseudo
    ) where

import Data.List (stripPrefix)
import Text.Read (readMaybe)
import Data.Maybe (mapMaybe)
import Whitespace (Tokens,Token(..))
import Data.Char (ord)


bits_to_tokens :: [Int] -> Tokens 
bits_to_tokens t = map (\x -> if x==0 then Space else Tab) t

number_to_bits :: Integral a => a -> [Int]
number_to_bits 0 = [0]
number_to_bits n = loop n []
  where
    loop 0 acc = acc
    loop x acc = loop (div x 2) (fromIntegral (mod x 2) : acc)

convert_number :: String -> Maybe Tokens
convert_number str = case readMaybe str of 
    Nothing -> Nothing
    Just x  -> let
        sign = if signum x == 1 then Space else Tab
        tokens = bits_to_tokens . number_to_bits $ abs x
        in Just $ sign:tokens++[LF]

convert_label :: String -> Maybe Tokens
convert_label str = (++ [LF]) <$> (loop str [])
    where
        loop :: String -> Tokens -> Maybe Tokens
        loop [] acc = Just acc
        loop (x:xs) acc = case x of
            '0' -> loop xs (acc++[Space])
            '1' -> loop xs (acc++[Tab])
            _   -> Nothing

convert_char :: Char -> Maybe Tokens
convert_char = (convert_number . show . ord)



push_string :: String -> Maybe Tokens
push_string ('"':xs) = loop xs []
    where
        loop :: String -> Tokens -> Maybe Tokens
        loop [] acc        = Nothing  -- unmatched "
        loop ('"':xs) acc  = Just acc -- properly closed
        loop (x:xs) acc = case convert_char x of
            Just tokens -> loop xs (acc ++ [Space,Space] ++ tokens)
            Nothing     -> Nothing


parse_line :: String -> Maybe Tokens
-- Stack
parse_line (stripPrefix "pushString " -> Just x)   = push_string $ reverse x
parse_line (stripPrefix "push"      -> Just x)     = ([Space, Space] ++)     <$> convert_number x
parse_line (stripPrefix "dublicate" -> Just _)     = Just $ [Space, LF,Space]
parse_line (stripPrefix "swap"      -> Just _)     = Just $ [Space, LF,Tab]
parse_line (stripPrefix "discard"   -> Just _)     = Just $ [Space, LF,LF]
parse_line (stripPrefix "copy"      -> Just x)     = ([Space, Tab,Space] ++) <$> convert_number x
parse_line (stripPrefix "slide"     -> Just x)     = ([Space, Tab,LF] ++)    <$> convert_number x
-- Arithmetic
parse_line (stripPrefix "add" -> Just _)        = Just $ [Tab,Space, Space,Space]
parse_line (stripPrefix "sub" -> Just _)        = Just $ [Tab,Space, Space,Tab]
parse_line (stripPrefix "mul" -> Just _)        = Just $ [Tab,Space, Space,LF]
parse_line (stripPrefix "div" -> Just _)        = Just $ [Tab,Space, Tab,Space]
parse_line (stripPrefix "mod" -> Just _)        = Just $ [Tab,Space, Tab,Tab]
-- IO
parse_line (stripPrefix "readChar" -> Just _)   = Just $ [Tab,LF, Tab,Space]
parse_line (stripPrefix "readNum" -> Just _)    = Just $ [Tab,LF, Tab,Tab]
parse_line (stripPrefix "printChar" -> Just _)  = Just $ [Tab,LF, Space,Space]
parse_line (stripPrefix "printNum" -> Just _)   = Just $ [Tab,LF, Space,Tab]
parse_line (stripPrefix "dump" -> Just _)       = Just $ [Tab,LF, Tab,LF]
-- Flow
parse_line (stripPrefix "setMark " -> Just x)   = ([LF, Space,Space] ++) <$> convert_label x
parse_line (stripPrefix "call " -> Just x)      = ([LF, Space,Tab] ++)   <$> convert_label x
parse_line (stripPrefix "jump " -> Just x)      = ([LF, Space,LF] ++)    <$> convert_label x
parse_line (stripPrefix "jumpZero " -> Just x)  = ([LF, Tab,Space] ++)   <$> convert_label x
parse_line (stripPrefix "jumpNeg " -> Just x)   = ([LF, Tab,Tab] ++)     <$> convert_label x
parse_line (stripPrefix "return" -> Just _)    = Just $ [LF, Tab,LF]
parse_line (stripPrefix "exit" -> Just _)      = Just $ [LF, LF,LF]
-- Heap
parse_line (stripPrefix "store" -> Just _)      = Just $ [Tab,Tab, Space]
parse_line (stripPrefix "retreive" -> Just _)   = Just $ [Tab,Tab, Tab]

parse_line []       = Just []
parse_line ('#':xs) = Just []
parse_line _        = Nothing




to_tokens :: String -> Either String Tokens
to_tokens str = loop (lines str) 1 []
    where
        loop :: [String] -> Int -> Tokens -> Either String Tokens
        loop [] _ acc = Right acc
        loop (line : rest) i acc = case parse_line line of
            Just tokens -> loop rest (i + 1) (acc ++ tokens)
            Nothing     -> Left ("Error while parsing line " ++ show i)




from_pseudo :: String -> Either String String
from_pseudo str = 
    (map fn) <$> (to_tokens str)
    where
        fn Space = ' '
        fn Tab   = '\t'
        fn LF    = '\n'


map_to_whitespace :: String -> String -> String
map_to_whitespace (s:t:l:xs) str = 
    mapMaybe fn str where
        fn c 
            | c==s = Just ' '
            | c==t = Just '\t'
            | c==l = Just '\n'
            | otherwise = Nothing
map_to_whitespace _ str = error "The string for remapping must contain exactly three characters"