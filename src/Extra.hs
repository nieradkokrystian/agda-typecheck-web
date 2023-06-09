{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-unused-matches #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}
{-# OPTIONS_GHC -fno-warn-unused-binds #-}
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}
{-# OPTIONS_GHC -fno-warn-missing-export-lists #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module Extra where

import Types

import Web.Scotty
import qualified Network.Wai.Parse as NWP

import qualified Data.Text as T
import qualified Data.Text.Lazy as TL

import System.Random
import Data.List (genericReplicate)

import System.Environment
import Data.Aeson

import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy.Internal as BL
import qualified Data.ByteString.Char8 as BC

checkAndPrepareFiles :: [File] -> ATCEnv -> IO CheckRes
checkAndPrepareFiles fl env = do
  case Prelude.length fl of
    2 -> do
           let nLists = map (\(x,y) -> ((NWP.fileName y), (NWP.fileContent y))) fl
           case containsElements ["Problem.agda", "Problem.json"] (map (\(n,c)-> n) nLists) of
             False -> return $ Err $ "I expect files named: Problem.agda and Problem.json." ++ "\n\n You send: " ++ (show (map (\(n,c)-> n) nLists))
             True -> do
               rString <- randomString 
               let (agdaC, jsonC) = if (fst (Prelude.head nLists)) == "Problem.agda"
                     then (( snd(Prelude.head nLists)),(snd (Prelude.last nLists)))
                     else (( snd(Prelude.last nLists)),( snd(Prelude.head nLists))) 
                   filePath = (agdaExec env) ++ "Problem" ++ rString ++  ".agda"
                   metad = decode jsonC :: Maybe MetaD
               BS.writeFile filePath (BC.toStrict agdaC)
               case metad of
                 Nothing -> return $ Err "c"
                 Just m -> return $  Ok AgaType { problem = filePath
                                                , meta = m
                                                }

    _ -> return $ Err "Invalid list of attachments, expecting 2: Problem.agda and Problem.json."


loadConfigAndRun :: (ATCEnv  -> IO ()) -> IO ()
loadConfigAndRun mainAPI =
  do
  args <- getArgs
  case args of
     [configFileName] -> do
       mbCfg <- decodeFileStrict configFileName :: IO (Maybe ATCEnv)
       case mbCfg of
         Nothing ->
                   Prelude.putStrLn $ "Invalid JSON file format, check : " ++ configFileName
         Just cfg ->  mainAPI cfg
     _ ->
       Prelude.putStrLn $ show args ++  "\n\nInvalid number of arguments, please run the program again with one argument: config.json"



containsElements :: Eq a => [a] -> [a] -> Bool
containsElements xs ys = all (\x -> elem x ys) xs

randomString :: IO String
randomString = do
  gen <- newStdGen
  let chars = ['a'..'z'] ++ ['A'..'Z'] ++ ['0'..'9']
      randomChars = take 4 $ randomRs ('a', 'z') gen -- Modify this line to change the range of characters
  return randomChars
