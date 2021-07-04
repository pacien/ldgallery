-- ldgallery - A static generator which turns a collection of tagged
--             pictures into a searchable web gallery.
--
-- Copyright (C) 2019-2021  Pacien TRAN-GIRARD
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

module ItemProcessors
  ( ItemProcessor
  , itemFileProcessor
  , thumbnailFileProcessor
  ) where


import Data.Char (toLower)
import System.FilePath (takeExtension)

import Config (Resolution(..))
import Resource (ItemProcessor, Thumbnail(..), GalleryItemProps(..))
import Caching (Cache)
import FileProcessors
import Files


data Format =
    PictureFormat
  | PlainTextFormat
  | MarkdownFormat
  | PortableDocumentFormat
  | VideoFormat
  | AudioFormat
  | Unknown

formatFromPath :: Path -> Format
formatFromPath =
  maybe Unknown ((fromExt . map toLower) . takeExtension) . fileName
  where
    fromExt :: String -> Format
    fromExt ext = case ext of
      ".bmp" -> PictureFormat
      ".jpg" -> PictureFormat
      ".jpeg" -> PictureFormat
      ".png" -> PictureFormat
      ".tiff" -> PictureFormat
      ".hdr" -> PictureFormat
      ".gif" -> PictureFormat
      ".webp" -> PictureFormat
      ".txt" -> PlainTextFormat
      ".md" -> MarkdownFormat
      ".pdf" -> PortableDocumentFormat
      ".wav" -> AudioFormat
      ".oga" -> AudioFormat
      ".ogg" -> AudioFormat
      ".spx" -> AudioFormat
      ".opus" -> AudioFormat
      ".flac" -> AudioFormat
      ".m4a" -> AudioFormat
      ".mp3" -> AudioFormat
      ".ogv" -> VideoFormat
      ".ogx" -> VideoFormat
      ".webm" -> VideoFormat
      ".mkv" -> VideoFormat
      ".mp4" -> VideoFormat
      _ -> Unknown


type ItemFileProcessor a =
     FilePath -- ^ Filesystem input base path
  -> FilePath -- ^ Filesystem output base path
  -> FileName -- ^ Output class (subdir)
  -> ItemProcessor a


callFileProcessor :: (Path -> FileProcessor a) -> Cache a -> ItemFileProcessor a
callFileProcessor processorProvider withCache inputBase outputBase resClass itemPath resPath =
  withCache (processorProvider resPath)
    itemPath
    (resClass /> resPath)
    (localPath $ inputBase /> resPath)
    (localPath $ outputBase /> (resClass /> resPath))


itemFileProcessor :: Maybe Resolution -> Cache GalleryItemProps -> ItemFileProcessor GalleryItemProps
itemFileProcessor maxResolution =
  callFileProcessor (flip processorFor maxResolution . formatFromPath)
  where
    processorFor :: Format -> Maybe Resolution -> FileProcessor GalleryItemProps
    processorFor PictureFormat (Just maxRes) =
      transformThenDescribe (resizePictureUpTo maxRes) getPictureProps
    processorFor PictureFormat Nothing =
      transformThenDescribe copyFileProcessor getPictureProps
    processorFor PlainTextFormat _ = copyResource PlainText
    processorFor MarkdownFormat _ = copyResource Markdown
    processorFor PortableDocumentFormat _ = copyResource PDF
    processorFor VideoFormat _ = copyResource Video
    processorFor AudioFormat _ = copyResource Audio
    processorFor Unknown _ = copyResource Other
    -- TODO: handle video reencoding and others?


thumbnailFileProcessor :: Resolution -> Cache (Maybe Thumbnail) -> ItemFileProcessor (Maybe Thumbnail)
thumbnailFileProcessor maxRes =
  callFileProcessor (processorFor . formatFromPath)
  where
    processorFor :: Format -> FileProcessor (Maybe Thumbnail)
    processorFor PictureFormat = transformThenDescribe (resizePictureUpTo maxRes) getThumbnailProps
    processorFor _ = noopProcessor
