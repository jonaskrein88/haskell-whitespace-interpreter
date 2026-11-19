import Whitespace
import ToWhitespace

import Data.Maybe (listToMaybe)
import System.Environment




main :: IO ()
main = getArgs >>= (\args ->
    case listToMaybe args of
        Nothing   -> putStrLn "No filepath provided"
        Just file -> readFile file >>= (run_whitespace . map_to_whitespace "STL")

    )
{--
main :: IO ()
main = getArgs >>= (\args ->
    case listToMaybe args of
        Nothing   -> putStrLn "No filepath provided"
        --Just file -> readFile file >>= (run_whitespace . stl_to_whitespace)
        Just file -> readFile file >>= (print . to_commands . tokenize . chars_to_whitespace)
    )
--}
