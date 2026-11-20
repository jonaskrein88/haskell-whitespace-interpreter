# haskell-whitespace-interpreter
Interpreter for the esoteric [Whitespace](https://esolangs.org/wiki/Whitespace) programming language in Haskell. Work in progress.

The language only uses three whitespace characters — _space_, _tab_, and _newline_ — as syntax. All other characters are ignored.


## usage

Some of the example code online is not really written in the actual whitespace characters but placeholders. To run these examples - or if you prefer to write code that you can actually see - you can use _map_to_whitespace_ to remap the proxy characters. This example maps _S_ _T_ and _L_ to space, tab and newline.

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

## whitespace transpiler

The module also contains a function that will transpile a human readable version of whitespace to actual Whitespace.

This example saves the code to a whitespace file which is then imported and run. 
```Haskell
main :: IO ()
main = getArgs >>= (\args ->
    case listToMaybe args of
        Nothing   -> putStrLn "No filepath provided"
        Just file -> readFile file >>= (\s ->
            case from_pseudo s of
                Left e  -> print e
                Right c -> let
                    wsfile = "whitespace.ws" in
                    writeFile wsfile c
                    >> readFile wsfile
                    >>= run_whitespace
            )
    )
```
Human readable code:
```python
pushString "enter two numbers: " # convenience function that pushes the characters in reverse order
printString 19                   # convenience function that repeats printChar x times
readNum
readNum
call 1011
exit

# function add_and_print
# (int, int) -> int
setMark 1011
add
pushString "the sum is: "
printString 12
copy 0
printNum
return
```

The resulting whitespace code in all its obfuscated beauty:
```whitespace
   	     
   			 	 
   			  		
   			  	 
   		  	 	
   		   	 
   		 		 	
   			 	 	
   		 			 
   	     
   		 				
   			 			
   			 	  
   	     
   			  	 
   		  	 	
   			 	  
   		 			 
   		  	 	
	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
			
		
 		 		




  	 		
	      	     
   			 	 
   			  		
   		 	  	
   	     
   		 		 	
   			 	 	
   			  		
   	     
   		  	 	
   		 	   
   			 	  
	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
   	 	 
	
 	
	

```

## debugging

There is an additional _dump_ function which will print out the interpreted program, stack, heap, callstack, and function pointer during execution. The command is 
```Tab LF Tab LF``` or _dump_ in the pseudo code.

You can also inspect the actual tokens or instructions via 
```Haskell
readFile file >>= (\code -> let
    tokens = tokenize code
    program = to_commands tokens
    in
    print tokens
    >> print program
    >> run_whitespace code
    )
```
