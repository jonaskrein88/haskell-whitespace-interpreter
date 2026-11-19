module Whitespace(
    run_whitespace,
    tokenize,
    to_commands,
    Command(..),
    Program,
    Token(..),
    Tokens)
where


import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.State.Strict (StateT, evalStateT, modify, get, state)
import System.IO (BufferMode(NoBuffering), hSetBuffering, stdout)

import qualified Data.Map.Strict as Map

import Data.Char (digitToInt,ord,chr)
import Data.List (foldl',(!?))
import Data.Maybe (mapMaybe)

data Token = Space | LF | Tab deriving (Show,Eq,Ord)
type Tokens = [Token]

type Label = Tokens
type Number = Int

data Command 
  = ReadChar
  | ReadNum
  | PrintChar
  | PrintNum
  | Dump
  | Push Number
  | Dublicate
  | Swap
  | Discard
  | Copy Number
  | Slide Number
  | Add
  | Sub
  | Mul
  | Div
  | Mod
  | SetMark Label
  | Call Label
  | Jump Label
  | JumpZero Label
  | JumpNeg Label
  | Return
  | Exit
  | Store
  | Retreive
  deriving (Show)
  
type Program = [Command]


-- Numbers start with Space(+) or Tab(-)
-- then binary Space(0) or Tab(1)
-- and end with LF


binary_to_int :: String -> Int
binary_to_int = foldl' (\acc x -> acc * 2 + digitToInt x) 0

tokens_to_number :: Tokens -> Int
tokens_to_number (t:ts) = let 
  str = map (\x -> if x==Space then '0' else '1') ts
  sign = case t of
    Space -> 1
    Tab -> -1
    LF -> error "number starts with LF"
  in sign * binary_to_int str

parse_number :: Tokens -> (Number, Tokens)
parse_number xs = loop xs [] where
  loop :: Tokens -> Tokens -> (Number, Tokens)
  loop (LF:xs) accum = let number = tokens_to_number accum in (number, xs)
  loop (x:xs) accum = loop xs $ accum ++ [x]
  loop [] _ = error "Encountered EOF while tryin to parse number"

parse_label :: Tokens -> (Label, Tokens)
parse_label xs = loop xs [] where
  loop :: Tokens -> Tokens -> (Label, Tokens)
  loop (LF:xs) accum = (accum, xs)
  loop (x:xs) accum = loop xs $ accum ++ [x]
  loop [] _ = error "Encountered EOF while tryin to parse label"


to_commands :: Tokens -> [Command]
to_commands [] = []
-- Stack
to_commands (Space: Space:xs)        = (Push number) : to_commands ys where (number, ys) = parse_number xs
to_commands (Space: LF:Space:xs)     = Dublicate : to_commands xs
to_commands (Space: LF:Tab:xs)       = Swap : to_commands xs
to_commands (Space: LF:LF:xs)        = Discard : to_commands xs
to_commands (Space: Tab:Space:xs)    = (Copy number) : to_commands ys where (number, ys) = parse_number xs
to_commands (Space: Tab:LF:xs)       = (Slide number) : to_commands ys where (number, ys) = parse_number xs
-- IO
to_commands (Tab:LF: Tab:Space:xs)   = ReadChar  : to_commands xs
to_commands (Tab:LF: Tab:Tab:xs)     = ReadNum   : to_commands xs
to_commands (Tab:LF: Space:Space:xs) = PrintChar : to_commands xs
to_commands (Tab:LF: Space:Tab:xs)   = PrintNum  : to_commands xs
to_commands (Tab:LF: Tab:LF:xs)      = Dump      : to_commands xs
-- Arithmetic
to_commands (Tab:Space: Space:Space:xs)  = Add : to_commands xs
to_commands (Tab:Space: Space:Tab:xs)    = Sub : to_commands xs
to_commands (Tab:Space: Space:LF:xs)     = Mul : to_commands xs
to_commands (Tab:Space: Tab:Space:xs)    = Div : to_commands xs
to_commands (Tab:Space: Tab:Tab:xs)      = Mod : to_commands xs
-- Flow
to_commands (LF: Space:Space:xs)    = (SetMark label) : to_commands ys where (label, ys) = parse_label xs
to_commands (LF: Space:Tab:xs)      = (Call label) : to_commands ys where (label, ys) = parse_label xs
to_commands (LF: Space:LF:xs)       = (Jump label) : to_commands ys where (label, ys) = parse_label xs
to_commands (LF: Tab:Space:xs)      = (JumpZero label) : to_commands ys where (label, ys) = parse_label xs
to_commands (LF: Tab:Tab:xs)        = (JumpNeg label) : to_commands ys where (label, ys) = parse_label xs
to_commands (LF: Tab:LF:xs)         = Return : to_commands xs
to_commands (LF: LF:LF:xs)          = Exit : to_commands xs
-- Heap
to_commands (Tab:Tab: Space:xs)   = Store : to_commands xs
to_commands (Tab:Tab: Tab:xs)     = Retreive : to_commands xs

to_commands xs = error $ "not recognized " ++ (show xs)




type Stack = [Int]
type Heap  = Map.Map Int Int    -- address,value
type Marks = Map.Map Tokens Int -- label, index

data Memory = Memory {
  stack     :: Stack,
  heap      :: Heap,
  program   :: Program,
  pointer   :: Int,
  marks     :: Marks,
  callStack :: Stack
} deriving (Show)




generate_marks :: Program -> Marks
generate_marks p = loop p Map.empty 0
  where
  loop :: Program ->Marks -> Int ->Marks
  loop [] m _ = m
  loop (SetMark(label):xs) m i = let
    next = i+1
    newMap = Map.insert label next m
    in loop xs newMap next
  loop (x:xs) m i = loop xs m (i+1)


init_memory :: Program -> Memory
init_memory p = Memory {stack=[], heap=Map.empty, program=p, pointer=0, marks=marks, callStack=[]}
  where marks = generate_marks p




push :: Int -> StateT Memory IO ()
push x = modify (\m -> m {stack = x:stack m})

-- helper for IO
pop :: StateT Memory IO Int
pop = state $ \m -> pop' m
  where
  pop' :: Memory -> (Int, Memory)
  pop' m@(Memory {stack=x:xs}) = (x, m{stack=xs})
  pop' m@(Memory {stack=[]}) = error "Trying to pop from an empty stack"

dublicate :: StateT Memory IO ()
dublicate = modify (\m@(Memory {stack=x:xs}) -> m{stack=x:x:xs})

swap :: StateT Memory IO ()
swap = modify (\m@(Memory {stack=x:y:xs}) -> m{stack=y:x:xs})

discard :: StateT Memory IO ()
discard = pop >> pure ()

copy :: Int -> StateT Memory IO ()
copy x = modify (\m -> let 
  s = stack m 
  n = s !! x 
  in m{stack=n:s}
  )
  
slide :: Int -> StateT Memory IO ()
slide x = modify (\m -> let 
  s = drop x $ stack m 
  in m{stack=s}
  )


-- value must be on top
-- then adress
store :: StateT Memory IO ()
store = pop 
  >>= \value -> pop
  >>= \address -> modify (\m ->
  let new_heap = Map.insert address value (heap m)
  in m{heap=new_heap}
  )

retreive :: StateT Memory IO ()
retreive = pop 
  >>= \address -> modify (\m -> 
    case Map.lookup address (heap m) of
      Nothing     -> error "trying to read from invalid heap adress"
      Just(value) -> let new_heap = Map.insert address value (heap m)
        in m{heap=new_heap}
  )



-- generic function for arithmetic
-- since all of them use the top two items on the stack
eval :: (Int -> Int -> Int) -> StateT Memory IO ()
eval fn = pop
  >>= \x -> pop
  >>= \y -> push (fn x y)







instruction_at_mark :: Label -> Marks -> Int
instruction_at_mark label marks =
  case Map.lookup label marks of
    Nothing -> error $ "no mark found with label " ++ show label
    Just x -> x

-- no need to increment pointer, since we are calling exec/fetch afterwards
call :: Label -> StateT Memory IO ()
call label = modify (\m -> let
    new_pointer   = instruction_at_mark label (marks m)
    new_callStack = (pointer m) : (callStack m)
    in m{pointer=new_pointer, callStack = new_callStack})

end_routine :: StateT Memory IO ()
end_routine = modify (\m -> let
    (x:xs) = (callStack m)
    in m{pointer=x, callStack = xs})

jump :: Label -> StateT Memory IO ()
jump label = modify (\m -> let
    new_pointer   = instruction_at_mark label (marks m)
    in m{pointer=new_pointer})

jump_if :: Label -> (Int -> Bool) -> StateT Memory IO ()
jump_if label fn = modify (\m -> let
    (x:_) = stack m
    new_pointer  = instruction_at_mark label (marks m)
    in if fn x then m{pointer=new_pointer}
    else m
    )


printNum :: StateT Memory IO ()
printNum = pop >>= liftIO . putStr . show

printChar :: StateT Memory IO ()
printChar = pop >>= liftIO . putChar . chr

readNum :: StateT Memory IO ()
readNum = liftIO readLn >>= push

readChar :: StateT Memory IO ()
readChar = liftIO getChar >>= push . ord

dump_memory :: StateT Memory IO ()
dump_memory = get >>= liftIO . print

-- increment pointer and return next command
fetch :: StateT Memory IO (Maybe Command)
fetch = state $ \m -> case (program m) !? (pointer m) of
  Nothing -> (Nothing, m)
  Just x  -> (Just x, m{pointer = pointer m + 1})



exec :: StateT Memory IO ()
exec = fetch >>= (\maybe_cmd ->
  case maybe_cmd of
    Nothing         -> pure ()
    Just Exit       -> pure ()
    Just (Push x)   -> push x >> exec
    Just Dublicate  -> dublicate >> exec
    Just Swap       -> swap >> exec
    Just Discard    -> discard >> exec
    Just (Copy x)   -> copy x >> exec
    Just (Slide x)  -> slide x >> exec
    Just Store      -> store >> exec
    Just Add        -> eval (+) >> exec
    Just Sub        -> eval (-) >> exec
    Just Mul        -> eval (*) >> exec
    Just Div        -> eval quot >> exec -- rounds negative numbers towards zero; C behavior
    Just Mod        -> eval mod >> exec
    Just Dump       -> dump_memory >> exec
    Just PrintNum   -> printNum >> exec
    Just PrintChar  -> printChar >> exec
    Just ReadNum    -> readNum >> exec
    Just ReadChar   -> readChar >> exec
    Just (SetMark _)  -> exec
    Just (Jump l)     -> jump l >> exec
    Just (JumpNeg l)  -> jump_if l (<0) >> exec
    Just (JumpZero l) -> jump_if l (==0) >> exec
    Just (Call l)     -> call l >> exec
    Just Return       -> end_routine >> exec
    Just x            -> (liftIO . print) ("Not implemented yet: " ++ show x)
  )


tokenize :: String -> Tokens
tokenize = mapMaybe fn
    where 
        fn ' '  = Just Space
        fn '\n' = Just LF
        fn '\t' = Just Tab
        fn _    = Nothing


run_whitespace :: String -> IO ()
run_whitespace str = hSetBuffering stdout NoBuffering >> evalStateT exec memory
    where memory = init_memory $ to_commands $ tokenize str





