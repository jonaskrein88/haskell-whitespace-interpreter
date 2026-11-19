import Whitespace
import ToWhitespace

import Data.Maybe (listToMaybe)
import System.Environment



{--
main :: IO ()
main = getArgs >>= (\args ->
    case listToMaybe args of
        Nothing   -> putStrLn "No filepath provided"
        Just file -> readFile file >>= (run_whitespace . map_to_whitespace "STL")

    )
--}
main :: IO ()
main = getArgs >>= (\args ->
    case listToMaybe args of
        Nothing   -> putStrLn "No filepath provided"
        Just file -> readFile file >>= (\s -> let
            code =  map_to_whitespace "STL" s
            tokens = tokenize code
            program = to_commands tokens
            in 
            print tokens
            >> print program
            >> run_whitespace code
            )
    )

