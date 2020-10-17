<!-- ldgallery - A static generator which turns a collection of tagged
--             pictures into a searchable web gallery.
--
-- Copyright (C) 2019-2020  Guillaume FOUET
--               2020       Pacien TRAN-GIRARD
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
  <div class="flex command-btns">
    <a class="link" :title="$t('command.search')" tabindex="20" @click="$uiStore.toggleFullWidth()">
      <fa-icon :icon="commandToggleSearchPanelIcon" size="lg" />
    </a>
    <ld-command-sort tabindex="21" />
    <a
      :class="{ disabled: isEntryPoint }"
      class="link command-secondary"
      :title="$t('command.back')"
      tabindex="22"
      @click="isEntryPoint || $router.back()"
    >
      <fa-icon icon="arrow-left" size="lg" />
    </a>
    <router-link :class="{ disabled: isRoot }" :title="$t('command.parent')" :to="parent" tabindex="23">
      <fa-icon icon="folder" size="xs" />
      <fa-icon icon="level-up-alt" size="lg" />
    </router-link>
  </div>
</template>

<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { RawLocation } from "vue-router";

@Component
export default class LdCommand extends Vue {
  @Prop({ type: Array, required: true }) readonly currentItemPath!: Gallery.Item[];

  get commandToggleSearchPanelIcon(): string {
    return this.$uiStore.fullWidth ? "search" : "angle-double-left";
  }

  get isRoot(): boolean {
    return this.currentItemPath.length <= 1 && !this.$uiStore.searchMode;
  }

  get isEntryPoint(): boolean {
    return history.state?.ldgallery === "ENTRYPOINT"; // Set by MainLayout.vue
  }

  get parent(): RawLocation {
    if (this.$uiStore.searchMode) return this.$route.path;
    if (this.currentItemPath.length > 1) return this.currentItemPath[this.currentItemPath.length - 2];
    return "";
  }
}
</script>

<style lang="scss">
@import "~@/assets/scss/_buefy_variables.scss";
@import "~@/assets/scss/theme.scss";

.command-btns {
  background-color: $command-buttons-bgcolor;
  justify-content: space-around;
  vertical-align: middle;
  align-items: center;
  flex: 0 0 $layout-left;

  > a {
    // normalise icon active boxes
    width: $layout-top;
    line-height: $layout-top;
    text-align: center;
    vertical-align: middle;
  }

  @media only screen and (max-width: $tablet) {
    flex: 0 1;

    > .command-secondary {
      display: none;
    }
  }
}
</style>
