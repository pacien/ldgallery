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

<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";

export interface keyboardAction {
  keys: string[];
  action: (e: KeyboardEvent) => any;
}

@Component
export default class LdKeyPress extends Vue {
  @Prop({ type: Array, required: true }) readonly actions!: keyboardAction[];
  @Prop({ type: String, default: "keyup" }) readonly event!: "keyup" | "keydown" | "keypress";

  mounted() {
    window.addEventListener(this.event, this.onEvent);
  }

  destroyed() {
    window.removeEventListener(this.event, this.onEvent);
  }

  render() {
    return null;
  }

  private onEvent(e: KeyboardEvent) {
    this.actions.filter(action => action.keys.includes(e.key)).forEach(action => action.action(e));
  }
}
</script>
