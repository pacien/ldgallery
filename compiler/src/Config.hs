-- ldgallery - A static generator which turns a collection of tagged
--             pictures into a searchable web gallery.
--
-- Copyright (C) 2019-2020  Pacien TRAN-GIRARD
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

module Config
  ( GalleryConfig(..)
  , CompilerConfig(..)
  , PictureScalingMethod, pictureScaling
  , readConfig
  ) where


import GHC.Generics (Generic)
import Data.Aeson (FromJSON, withText, withObject, (.:?), (.!=))
import qualified Data.Aeson as JSON

import Files (FileName)
import Input (decodeYamlFile)
import Resource (Resolution(..))
import Processors (PictureScaling(..))


newtype PictureScalingMethod = PictureScalingMethod
  { scaling :: PictureScaling
  } deriving (Generic, Show)

instance FromJSON PictureScalingMethod where
  parseJSON = withText "PictureScalingMethod" $ \text ->
    case text of
      "bilinear" -> return $ PictureScalingMethod Bilinear
      "dct" -> return $ PictureScalingMethod DCT
      _ -> fail "Invalid picture scaling method"


data CompilerConfig = CompilerConfig
  { galleryName :: String
  , includedDirectories :: [String]
  , excludedDirectories :: [String]
  , includedFiles :: [String]
  , excludedFiles :: [String]
  , tagsFromDirectories :: Int
  , thumbnailMaxResolution :: Resolution
  , pictureMaxResolution :: Maybe Resolution
  , pictureScalingMethod :: PictureScalingMethod
  , jpegExportQuality :: Int
  } deriving (Generic, Show)

pictureScaling :: CompilerConfig -> PictureScaling
pictureScaling = scaling . pictureScalingMethod

instance FromJSON CompilerConfig where
  parseJSON = withObject "CompilerConfig" $ \v -> CompilerConfig
    <$> v .:? "galleryName" .!= "Gallery"
    <*> v .:? "includedDirectories" .!= ["*"]
    <*> v .:? "excludedDirectories" .!= []
    <*> v .:? "includedFiles" .!= ["*"]
    <*> v .:? "excludedFiles" .!= []
    <*> v .:? "tagsFromDirectories" .!= 0
    <*> v .:? "thumbnailMaxResolution" .!= (Resolution 400 400)
    <*> v .:? "pictureMaxResolution"
    <*> v .:? "pictureScalingMethod" .!= PictureScalingMethod DCT
    <*> v .:? "jpegExportQuality" .!= 80


data GalleryConfig = GalleryConfig
  { compiler :: CompilerConfig
  , viewer :: JSON.Object
  } deriving (Generic, FromJSON, Show)

readConfig :: FileName -> IO GalleryConfig
readConfig = decodeYamlFile
