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

import Vue from "vue";
import VueRouter from "vue-router";
import MainGallery from "@/views/MainGallery.vue";

Vue.use(VueRouter);

// async way : component: () => import(/* webpackChunkName: "MainGallery" */ "@/views/MainGallery.vue"),

const routes = [
  {
    path: "*",
    name: "MainGallery",
    component: MainGallery,
    props: true
  },
];

const router = new VueRouter({
  routes,
});

export default router;
