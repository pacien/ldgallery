/* ldgallery - A static generator which turns a collection of tagged
--             pictures into a searchable web gallery.
--
-- Copyright (C) 2019-2020  Guillaume FOUET
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
*/

import { ItemType } from "./ItemType";

export type ItemSortStr = "title_asc" | "date_asc" | "date_desc";

export interface Config {
  galleryRoot: string;
  galleryIndex?: string;
  initialItemSort?: ItemSortStr;
  initialTagDisplayLimit?: number;
}

export interface Properties {
  galleryTitle: string;
  tagCategories: RawTag[];
}
export interface Index {
  properties: Properties;
  tree: DirectoryItem;
}

export interface OtherItem extends Item {
  properties: OtherProperties;
}
export interface PictureItem extends Item {
  properties: PictureProperties;
}
export interface PlainTextItem extends Item {
  properties: PlainTextProperties;
}
export interface MarkdownItem extends Item {
  properties: MarkdownProperties;
}
export interface PDFItem extends Item {
  properties: PDFProperties;
}
export interface VideoItem extends Item {
  properties: VideoProperties;
}
export interface AudioItem extends Item {
  properties: AudioProperties;
}
export interface DirectoryItem extends Item {
  properties: DirectoryProperties;
}
export interface Item {
  title: string;
  datetime: string;
  description: string;
  tags: RawTag[];
  path: string;
  thumbnail?: Thumbnail;
  properties:
    | OtherProperties
    | PictureProperties
    | PlainTextProperties
    | MarkdownProperties
    | PDFProperties
    | VideoProperties
    | AudioProperties
    | DirectoryProperties;
}
export interface Resolution {
  width: number;
  height: number;
}
export interface OtherProperties {
  type: ItemType.OTHER;
  resource: string;
}
export interface PictureProperties {
  type: ItemType.PICTURE;
  resource: string;
  resolution: Resolution;
}
export interface PlainTextProperties {
  type: ItemType.PLAINTEXT;
  resource: string;
}
export interface MarkdownProperties {
  type: ItemType.MARKDOWN;
  resource: string;
}
export interface PDFProperties {
  type: ItemType.PDF;
  resource: string;
}
export interface VideoProperties {
  type: ItemType.VIDEO;
  resource: string;
}
export interface AudioProperties {
  type: ItemType.AUDIO;
  resource: string;
}
export interface DirectoryProperties {
  type: ItemType.DIRECTORY;
  items: Item[];
}

export interface Thumbnail {
  resource: string;
  resolution: Resolution;
}
export type RawTag = string;
