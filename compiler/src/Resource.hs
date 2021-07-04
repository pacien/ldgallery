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

module Resource
  ( ItemProcessor
  , GalleryItem(..)
  , GalleryItemProps(..)
  , Resolution(..)
  , Resource(..)
  , Thumbnail(..)
  , buildGalleryTree
  , galleryCleanupResourceDir
  , flattenGalleryTree
  ) where


import Control.Concurrent.ParallelIO.Global (parallel)
import Data.List (sortOn)
import Data.List.Ordered (minusBy)
import Data.Char (toLower)
import Data.Maybe (mapMaybe, fromMaybe)
import Data.Function ((&))
import Data.Functor ((<&>))
import qualified Data.Set as Set
import Data.Text (pack, unpack, breakOn)
import Data.Time.Clock (UTCTime)
import Data.Time.LocalTime (ZonedTime, utc, utcToZonedTime, zonedTimeToUTC)
import Data.Time.Format (formatTime, parseTimeM, defaultTimeLocale)
import Safe.Foldable (maximumByMay)

import GHC.Generics (Generic)
import Data.Aeson (ToJSON, FromJSON, genericToJSON, genericToEncoding, genericParseJSON)
import qualified Data.Aeson as JSON

import Files
import Config (Resolution(..), TagsFromDirectoriesConfig(..))
import Input (InputTree(..), Sidecar(..))


encodingOptions :: JSON.Options
encodingOptions = JSON.defaultOptions
  { JSON.fieldLabelModifier = map toLower
  , JSON.constructorTagModifier = map toLower
  , JSON.sumEncoding = JSON.defaultTaggedObject
      { JSON.tagFieldName = "type"
      , JSON.contentsFieldName = "contents"
      }
  }


type Tag = String

data Resource = Resource
  { resourcePath :: Path
  , modTime :: UTCTime
  } deriving (Generic, Show)

instance ToJSON Resource where
  toJSON Resource{resourcePath, modTime} =
    JSON.String $ pack (webPath resourcePath ++ "?" ++ timestamp)
    where
      timestamp = formatTime defaultTimeLocale "%s" modTime

instance FromJSON Resource where
  parseJSON = JSON.withText "Resource" (unpackRes . breakOn "?")
    where
      unpackRes (resPathStr, modTimeStr) =
        Resource (fromWebPath $ unpack resPathStr)
        <$> parseTimeM True defaultTimeLocale "?%s" (unpack modTimeStr)


data GalleryItemProps =
    Directory { items :: [GalleryItem] }
  | Picture
    { resource :: Resource
    , resolution :: Resolution }
  | PlainText { resource :: Resource }
  | Markdown { resource :: Resource }
  | PDF { resource :: Resource }
  | Video { resource :: Resource }
  | Audio { resource :: Resource }
  | Other { resource :: Resource }
  deriving (Generic, Show)

instance ToJSON GalleryItemProps where
  toJSON = genericToJSON encodingOptions
  toEncoding = genericToEncoding encodingOptions

instance FromJSON GalleryItemProps where
  parseJSON = genericParseJSON encodingOptions


data Thumbnail = Thumbnail
  { resource :: Resource
  , resolution :: Resolution
  } deriving (Generic, Show, ToJSON, FromJSON)


data GalleryItem = GalleryItem
  { title :: String
  , datetime :: ZonedTime
  , description :: String
  , tags :: [Tag]
  , path :: Path
  , thumbnail :: Maybe Thumbnail
  , properties :: GalleryItemProps
  } deriving (Generic, Show, ToJSON, FromJSON)


type ItemProcessor a =
     Path -- Item path
  -> Path -- Resource Path
  -> IO a


buildGalleryTree ::
     ItemProcessor GalleryItemProps -> ItemProcessor (Maybe Thumbnail) -> TagsFromDirectoriesConfig
  -> InputTree -> IO GalleryItem
buildGalleryTree processItem processThumbnail tagsFromDirsConfig =
  mkGalleryItem []
  where
    mkGalleryItem :: [Tag] -> InputTree -> IO GalleryItem
    mkGalleryItem inheritedTags InputFile{path, modTime, sidecar, thumbnailPath} =
      do
        let itemPath = "/" /> path
        properties <- processItem itemPath path
        processedThumbnail <- processThumbnail itemPath (thumbnailPath ?? path)
        return GalleryItem
          { title = Input.title sidecar ?? fileName path ?? ""
          , datetime = Input.datetime sidecar ?? toZonedTime modTime
          , description = Input.description sidecar ?? ""
          , tags = unique ((Input.tags sidecar ?? []) ++ inheritedTags ++ parentDirTags path)
          , path = itemPath
          , thumbnail = processedThumbnail
          , properties = properties }

    mkGalleryItem inheritedTags InputDir{path, modTime, sidecar, thumbnailPath, items} =
      do
        let itemPath = "/" /> path
        let dirTags = (Input.tags sidecar ?? []) ++ inheritedTags
        processedItems <- parallel $ map (mkGalleryItem dirTags) items
        processedThumbnail <- maybeThumbnail itemPath thumbnailPath
        return GalleryItem
          { title = Input.title sidecar ?? fileName path ?? ""
          , datetime = Input.datetime sidecar ?? mostRecentModTime processedItems
                                              ?? toZonedTime modTime
          , description = Input.description sidecar ?? ""
          , tags = unique (aggregateTags processedItems ++ parentDirTags path)
          , path = itemPath
          , thumbnail = processedThumbnail
          , properties = Directory processedItems }

    infixr ??
    (??) :: Maybe a -> a -> a
    (??) = flip fromMaybe

    unique :: Ord a => [a] -> [a]
    unique = Set.toList . Set.fromList

    parentDirTags :: Path -> [Tag]
    parentDirTags (Path elements) =
        drop 1 elements
      & take (fromParents tagsFromDirsConfig)
      & map (prefix tagsFromDirsConfig ++)

    aggregateTags :: [GalleryItem] -> [Tag]
    aggregateTags = concatMap (\item -> tags (item::GalleryItem))

    maybeThumbnail :: Path -> Maybe Path -> IO (Maybe Thumbnail)
    maybeThumbnail _ Nothing = return Nothing
    maybeThumbnail itemPath (Just thumbnailPath) = processThumbnail itemPath thumbnailPath

    mostRecentModTime :: [GalleryItem] -> Maybe ZonedTime
    mostRecentModTime =
      maximumByMay comparingTime . map (datetime::(GalleryItem -> ZonedTime))

    comparingTime :: ZonedTime -> ZonedTime -> Ordering
    comparingTime l r = compare (zonedTimeToUTC l) (zonedTimeToUTC r)

    toZonedTime :: UTCTime -> ZonedTime
    toZonedTime = utcToZonedTime utc


flattenGalleryTree :: GalleryItem -> [GalleryItem]
flattenGalleryTree dir@(GalleryItem _ _ _ _ _ _ (Directory items)) =
  dir : concatMap flattenGalleryTree items
flattenGalleryTree simple = [simple]


galleryOutputDiff :: GalleryItem -> FSNode -> [Path]
galleryOutputDiff resources ref =
  filesystemPaths ref \\ compiledPaths (flattenGalleryTree resources)
  where
    filesystemPaths :: FSNode -> [Path]
    filesystemPaths = map Files.path . tail . flattenDir

    compiledPaths :: [GalleryItem] -> [Path]
    compiledPaths items =
      resPaths items ++ thumbnailPaths items
      & concatMap subPaths

    resPaths :: [GalleryItem] -> [Path]
    resPaths = mapMaybe (resPath . properties)

    resPath :: GalleryItemProps -> Maybe Path
    resPath Directory{} = Nothing
    resPath resourceProps =
        Just
      $ resourcePath
      $ (resource :: (GalleryItemProps -> Resource)) resourceProps

    thumbnailPaths :: [GalleryItem] -> [Path]
    thumbnailPaths =
        map (resourcePath . (resource :: (Thumbnail -> Resource)))
      . mapMaybe thumbnail

    (\\) :: [Path] -> [Path] -> [Path]
    a \\ b = minusOn orderedForm (sortOn orderedForm a) (sortOn orderedForm b)
      where
        orderedForm :: Path -> WebPath
        orderedForm = webPath

        minusOn :: Ord b => (a -> b) -> [a] -> [a] -> [a]
        minusOn f l r = map snd $ minusBy comparingFst (packRef f l) (packRef f r)

        packRef :: (a -> b) -> [a] -> [(b, a)]
        packRef f = map (\x -> let y = f x in y `seq` (y, x))

        comparingFst :: Ord b => (b, a) -> (b, a) -> Ordering
        comparingFst (l, _) (r, _) = compare l r


galleryCleanupResourceDir :: GalleryItem -> FileName -> IO ()
galleryCleanupResourceDir resourceTree outputDir =
  readDirectory outputDir
  <&> galleryOutputDiff resourceTree . root
  <&> sortOn ((0 -) . pathLength) -- nested files before their parent dirs
  <&> map (localPath . (/>) outputDir)
  >>= mapM_ remove
