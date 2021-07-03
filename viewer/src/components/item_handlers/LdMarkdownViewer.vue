<template>
  <b-loading v-if="isLoading" active />
  <Markdown v-else-if="markdown" class="flex-grow-1" :markdown="markdown" />
</template>

<script lang="ts">
import { MarkdownItem } from "@/@types/gallery";
import { Markdown } from "@/components/async";
import FetchWithCheck from "@/services/fetchWithCheck";
import { Component, Prop, Vue } from "vue-property-decorator";

@Component({
  components: {
    Markdown,
  },
})
export default class LdMarkdownViewer extends Vue {
  @Prop({ required: true }) readonly item!: MarkdownItem;

  isLoading: boolean = true;
  markdown: string | null = null;

  created() {
    this.fetchMarkdown();
  }

  get itemResourceUrl(): string {
    return this.$galleryStore.resourceRoot + this.item.properties.resource;
  }

  fetchMarkdown() {
    FetchWithCheck.get(this.itemResourceUrl)
      .then(response => response.text())
      .then(text => (this.markdown = text))
      .finally(() => (this.isLoading = false))
      .catch(this.displayError);
  }

  displayError(reason: any) {
    this.$buefy.snackbar.open({
      message: `${reason}`,
      actionText: this.$t("snack.retry"),
      position: "is-top",
      type: "is-warning",
      onAction: this.fetchMarkdown,
    });
  }
}
</script>

<style lang="scss" module>
.splashscreen {
  display: flex;
  flex-flow: column;
  align-items: center;
  padding: 32px;
}
.buttonOkay {
  min-width: 310px;
  align-self: center;
}
</style>
