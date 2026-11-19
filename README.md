# haskell-whitespace-interpreter
Interpreter for the esoteric [Whitespace](https://esolangs.org/wiki/Whitespace) programming language in Haskell. Work in progress.



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

I also wrote a small snippet that will transpile a human readable version of the commands to Whitespace.
This example will save to an intermediate whitespace file and run it.
```Haskell
main :: IO ()
main = getArgs >>= (\args ->
    case listToMaybe args of
        Nothing   -> putStrLn "No filepath provided"
        Just file -> readFile file >>= (\s ->
            case from_pseudo s of
                Left e  -> print e
                Right c -> let
                    wsfile = "converted.ws" in
                    writeFile wsfile c
                    >> readFile wsfile
                    >>= run_whitespace
            )
    )
```
```
pushString "enter two numbers: "
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
printChar
readNum
readNum
call 1011
exit

setMark 1011
add
printNum
return
```

The resulting whitespace code in all its obfuscated beauty:
```whitespace
   	     
   			 	 
   			  		
   			  	 
   		  	 	
   		   	 
   		 		 	
   			 	 	
   		 			 
   	     
   		 				
   			 			
   			 	  
   	     
   			  	 
   		  	 	
   			 	  
   		 			 
   		  	 	
	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
  	
			
		
 		 		




  	 		
	   	
 	
	

```

## debugging

For debugging I added a _dump_ function which will print out the program, stack, heap, callstack, and function pointer during execution. The command is 
```Tab LF Tab LF```.

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
