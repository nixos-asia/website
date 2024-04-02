{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}

{-# HLINT ignore "Use camelCase" #-}

module Main where

import Foreign.C.String (CString, peekCString)

-- | The `hello` function exported by the `rust_nix_template` library.
foreign import ccall "hello" hello_rust :: IO CString

-- | Call `hello_rust` and convert the result to a Haskell `String`.
hello_haskell :: IO String
hello_haskell = hello_rust >>= peekCString

main :: IO ()
main = hello_haskell >>= putStrLn
