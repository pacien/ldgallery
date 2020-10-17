<!-- ldgallery - A static generator which turns a collection of tagged
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
-->

<template>
  <b-taginput
    v-model="model"
    :placeholder="$t('tagInput.placeholder')"
    autocomplete
    ellipsis
    attached
    :data="filteredTags"
    field="display"
    type="is-black"
    size="is-medium"
    class="paneltag-input"
    tabindex="10"
    @typing="searchTags"
    @add="clearCurrentFilter"
    @remove="clearCurrentFilter"
    @keydown.enter.native="onKeyEnter"
  >
    <template slot-scope="props">{{ displayOption(props.option) }}</template>
    <template slot="empty">{{ $t("tagInput.nomatch") }}</template>
  </b-taginput>
</template>

<script lang="ts">
import { Component, Vue, Prop, PropSync, Emit } from "vue-property-decorator";
import { Operation } from "@/@types/Operation";
import Navigation from "@/services/navigation";
import IndexFactory from "@/services/indexfactory";

@Component
export default class LdTagInput extends Vue {
  @Prop({ required: true }) readonly tagsIndex!: Tag.Index;
  @PropSync("searchFilters", { type: Array, required: true }) model!: Tag.Search[];

  currentFilter: string = "";
  filteredTags: Tag.Search[] = [];

  displayOption(option: Tag.Search): string {
    return `${option.display} (${option.items.length})`;
  }

  filterAlreadyPresent(newSearch: Tag.Search) {
    return !this.model.find(
      currentSearch =>
        currentSearch.tag === newSearch.tag && (!currentSearch.parent || currentSearch.parent === newSearch.parent)
    );
  }

  searchTags(filter: string) {
    this.currentFilter = filter;
    this.filteredTags = IndexFactory.searchTags(this.tagsIndex, filter, false)
      .filter(this.filterAlreadyPresent)
      .sort((a, b) => b.items.length - a.items.length);
  }

  clearCurrentFilter() {
    // Necessary for @keydown.enter.native, nexttick is too short
    setTimeout(() => {
      this.currentFilter = "";
      this.filteredTags = [];
    });
  }

  onKeyEnter(e: KeyboardEvent) {
    if (!this.currentFilter) this.onkeyenterEmpty(e);
  }

  @Emit()
  onkeyenterEmpty(e: KeyboardEvent) {
    return e;
  }
}
</script>

<style lang="scss">
.paneltag-input .autocomplete .dropdown-content {
  max-height: 300px;
}
</style>
