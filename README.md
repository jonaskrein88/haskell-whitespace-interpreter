# haskell-whitespace-interpreter
Interpreter for the esoteric [Whitespace](https://esolangs.org/wiki/Whitespace) programming language in Haskell



## usage

Some of the example code online is not really written in the actual whitespace characters but placeholders. To run these examples - or if you prefer to write code that you can actually see - you can use _map_to_whitespace_ to remap the proxy characters. This example maps _S_ _T_ and _L_ to space, tab and newline.

You can of course also use this function to convert the proxy characters into pure whitespace code, which then can be executed directly with much more of a wow factor :)
```Haskell
import Whitespace
import ToWhitespace
import Data.Maybe (listToMaybe)
import System.Environment

main :: IO ()
main = getArgs >>= (\args ->
    case listToMaybe args of
        Nothing   -> putStrLn "No filepath provided"
        Just file -> readFile file >>= (run_whitespace . map_to_whitespace "STL")
```

## debugging

For debugging I added a _dump_ function which will print out the program, stack, heap, callstack, and function pointer during execution. The command is 
```Tab LF Tab LF```.

You can also inspect the actual tokens or instructions via 
```Haskell
readFile file >>= (\s -> let
            code =  map_to_whitespace "STL" s
            tokens = tokenize code
            program = to_commands tokens
            in 
            print tokens
            >> print program
            >> run_whitespace code
            )
```
