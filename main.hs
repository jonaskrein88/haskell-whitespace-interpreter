import Whitespace
import ToWhitespace(map_to_whitespace, from_pseudo)

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
{--
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
--}

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
