-- ldgallery - A static generator which turns a collection of tagged
--             pictures into a searchable web gallery.
--
-- Copyright (C) 2021  Pacien TRAN-GIRARD
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

{-# LANGUAGE CPP #-}

module ViewerDist where

#ifndef FLAG_PORTABLE

import Paths_ldgallery_compiler (getDataFileName)

viewerDistPath = getDataFileName "viewer"

#else

import Data.Functor ((<&>))
import System.FilePath (takeDirectory, (</>))
import System.Environment (getExecutablePath)

viewerDistPath = fmap takeDirectory getExecutablePath <&> (</> "viewer")

#endif

viewerDistPath :: IO FilePath
