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

module Processors
  ( Resolution(..)
  , ItemFileProcessor, itemFileProcessor
  , ThumbnailFileProcessor, thumbnailFileProcessor
  , skipCached, withCached
  ) where


import Control.Exception (Exception, throwIO)
import Data.Function ((&))
import Data.Ratio ((%))
import Data.Char (toLower)

import System.Directory hiding (copyFile)
import qualified System.Directory
import System.FilePath

import Codec.Picture
import Codec.Picture.Extra -- TODO: compare DCT and bilinear (and Lanczos, but it's not implemented)

import Resource
  ( ItemProcessor, ThumbnailProcessor
  , GalleryItemProps(..), Resolution(..) )

import Files


data ProcessingException = ProcessingException FilePath String deriving Show
instance Exception ProcessingException


data PictureFileFormat = Bmp | Jpg | Png | Tiff | Hdr | Gif

-- TODO: handle video, music, text...
data Format = PictureFormat PictureFileFormat | Unknown

formatFromPath :: Path -> Format
formatFromPath =
  maybe Unknown fromExt
  . fmap (map toLower)
  . fmap takeExtension
  . fileName
  where
    fromExt :: String -> Format
    fromExt ".bmp" = PictureFormat Bmp
    fromExt ".jpg" = PictureFormat Jpg
    fromExt ".jpeg" = PictureFormat Jpg
    fromExt ".png" = PictureFormat Png
    fromExt ".tiff" = PictureFormat Tiff
    fromExt ".hdr" = PictureFormat Hdr
    fromExt ".gif" = PictureFormat Gif
    fromExt _ = Unknown


type FileProcessor =
     FileName        -- ^ Input path
  -> FileName        -- ^ Output path
  -> IO ()

copyFileProcessor :: FileProcessor
copyFileProcessor inputPath outputPath =
  (putStrLn $ "Copying:\t" ++ outputPath)
  >> ensureParentDir (flip System.Directory.copyFile) outputPath inputPath

resizeStaticImageUpTo :: PictureFileFormat -> Resolution -> FileProcessor
resizeStaticImageUpTo Bmp = resizeStaticGeneric readBitmap saveBmpImage
-- TODO: parameterise export quality for jpg
resizeStaticImageUpTo Jpg = resizeStaticGeneric readJpeg (saveJpgImage 80)
resizeStaticImageUpTo Png = resizeStaticGeneric readPng savePngImage
resizeStaticImageUpTo Tiff = resizeStaticGeneric readTiff saveTiffImage
resizeStaticImageUpTo Hdr = resizeStaticGeneric readHDR saveRadianceImage
resizeStaticImageUpTo Gif = resizeStaticGeneric readGif saveGifImage'
  where
    saveGifImage' :: StaticImageWriter
    saveGifImage' outputPath image =
      saveGifImage outputPath image
      & either (throwIO . ProcessingException outputPath) id


type StaticImageReader = FilePath -> IO (Either String DynamicImage)
type StaticImageWriter = FilePath -> DynamicImage -> IO ()

resizeStaticGeneric :: StaticImageReader -> StaticImageWriter -> Resolution -> FileProcessor
resizeStaticGeneric reader writer maxRes inputPath outputPath =
  (putStrLn $ "Generating:\t" ++ outputPath)
  >>  reader inputPath
  >>= either (throwIO . ProcessingException inputPath) return
  >>= return . (fitDynamicImage maxRes)
  >>= ensureParentDir writer outputPath

fitDynamicImage :: Resolution -> DynamicImage -> DynamicImage
fitDynamicImage (Resolution boxWidth boxHeight) image =
  convertRGBA8 image
  & scaleBilinear targetWidth targetHeight
  & ImageRGBA8
  where
    picWidth = dynamicMap imageWidth image
    picHeight = dynamicMap imageHeight image
    resizeRatio = min (boxWidth % picWidth) (boxHeight % picHeight)
    targetWidth = floor $ resizeRatio * (picWidth % 1)
    targetHeight = floor $ resizeRatio * (picHeight % 1)


type Cache = FileProcessor -> FileProcessor

skipCached :: Cache
skipCached processor inputPath outputPath =
  removePathForcibly outputPath
  >> processor inputPath outputPath

withCached :: Cache
withCached processor inputPath outputPath =
  do
    isDir <- doesDirectoryExist outputPath
    if isDir then removePathForcibly outputPath else noop

    fileExists <- doesFileExist outputPath
    if fileExists then
      do
        needUpdate <- isOutdated True inputPath outputPath
        if needUpdate then update else skip
    else
      update

  where
    noop = return ()
    update = processor inputPath outputPath
    skip = putStrLn $ "Skipping:\t" ++ outputPath


type ItemFileProcessor =
     FileName        -- ^ Input base path
  -> FileName        -- ^ Output base path
  -> FileName        -- ^ Output class (subdir)
  -> ItemProcessor

itemFileProcessor :: Maybe Resolution -> Cache -> ItemFileProcessor
itemFileProcessor maxResolution cached inputBase outputBase resClass inputRes =
  cached processor inPath outPath
  >> return (props relOutPath)
  where
    relOutPath = resClass /> inputRes
    inPath = localPath $ inputBase /> inputRes
    outPath = localPath $ outputBase /> relOutPath
    (processor, props) = processorFor maxResolution $ formatFromPath inputRes

    processorFor :: Maybe Resolution -> Format -> (FileProcessor, Path -> GalleryItemProps)
    processorFor Nothing _ =
      (copyFileProcessor, Other)
    processorFor _ (PictureFormat Gif) =
      (copyFileProcessor, Picture) -- TODO: handle animated gif resizing
    processorFor (Just maxRes) (PictureFormat picFormat) =
      (resizeStaticImageUpTo picFormat maxRes, Picture)
    processorFor _ Unknown =
      (copyFileProcessor, Other) -- TODO: handle video reencoding and others?


type ThumbnailFileProcessor =
     FileName        -- ^ Input base path
  -> FileName        -- ^ Output base path
  -> FileName        -- ^ Output class (subdir)
  -> ThumbnailProcessor

thumbnailFileProcessor :: Resolution -> Cache -> ThumbnailFileProcessor
thumbnailFileProcessor maxRes cached inputBase outputBase resClass inputRes =
  cached <$> processorFor (formatFromPath inputRes)
  & process
  where
    relOutPath = resClass /> inputRes
    inPath = localPath $ inputBase /> inputRes
    outPath = localPath $ outputBase /> relOutPath

    process :: Maybe FileProcessor -> IO (Maybe Path)
    process Nothing = return Nothing
    process (Just proc) =
      proc inPath outPath
      >> return (Just relOutPath)

    processorFor :: Format -> Maybe FileProcessor
    processorFor (PictureFormat picFormat) =
      Just $ resizeStaticImageUpTo picFormat maxRes
    processorFor _ =
      Nothing
