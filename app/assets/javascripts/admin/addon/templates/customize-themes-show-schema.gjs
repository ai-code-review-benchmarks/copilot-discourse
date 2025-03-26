import { hash } from "@ember/helper";
import { LinkTo } from "@ember/routing";
import RouteTemplate from "ember-route-template";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import Editor from "admin/components/schema-theme-setting/editor";

export default RouteTemplate(
  <template>
    <div class="customize-themes-show-schema__header row">
      <LinkTo
        @route="adminCustomizeThemes.show"
        @model={{@model.theme.id}}
        class="btn-transparent customize-themes-show-schema__back"
      >
        {{icon "arrow-left"}}{{@model.theme.name}}
      </LinkTo>
      <h2>
        {{i18n
          "admin.customize.theme.schema.title"
          (hash name=@model.setting.setting)
        }}
      </h2>
    </div>

    <Editor @themeId={{@model.theme.id}} @setting={{@model.setting}} />
  </template>
);
