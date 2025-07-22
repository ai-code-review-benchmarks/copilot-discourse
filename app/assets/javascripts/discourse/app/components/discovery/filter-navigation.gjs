import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { next } from "@ember/runloop";
import { service } from "@ember/service";
import { and } from "truth-helpers";
import BulkSelectToggle from "discourse/components/bulk-select-toggle";
import DButton from "discourse/components/d-button";
import FilterTips from "discourse/components/discovery/filter-tips";
import PluginOutlet from "discourse/components/plugin-outlet";
import bodyClass from "discourse/helpers/body-class";
import icon from "discourse/helpers/d-icon";
import lazyHash from "discourse/helpers/lazy-hash";
import discourseDebounce from "discourse/lib/debounce";
import { bind } from "discourse/lib/decorators";
import { resettableTracked } from "discourse/lib/tracked-tools";
import { i18n } from "discourse-i18n";

export default class DiscoveryFilterNavigation extends Component {
  @service site;

  @tracked copyIcon = "link";
  @tracked copyClass = "btn-default";
  @tracked inputElement = null;
  @resettableTracked newQueryString = this.args.queryString;

  @bind
  updateQueryString(string) {
    this.newQueryString = string;
  }

  @action
  storeInputElement(element) {
    this.inputElement = element;
  }

  @action
  clearInput() {
    this.newQueryString = "";
    this.args.updateTopicsListQueryParams(this.newQueryString);
    next(() => {
      if (this.inputElement) {
        // required so child component is aware of the change
        this.inputElement.dispatchEvent(new Event("input", { bubbles: true }));
        this.inputElement.focus();
      }
    });
  }

  @action
  copyQueryString() {
    this.copyIcon = "check";
    this.copyClass = "btn-default ok";

    navigator.clipboard.writeText(window.location);

    discourseDebounce(this._restoreButton, 3000);
  }

  @bind
  _restoreButton() {
    if (this.isDestroying || this.isDestroyed) {
      return;
    }
    this.copyIcon = "link";
    this.copyClass = "btn-default";
  }

  @action
  handleKeydown(event) {
    if (event.key === "Enter" && this._allowEnterSubmit) {
      this.args.updateTopicsListQueryParams(this.newQueryString);
    }
  }

  @action
  blockEnterSubmit(value) {
    this._allowEnterSubmit = !value;
  }

  <template>
    {{bodyClass "navigation-filter"}}

    <section class="navigation-container">
      <div class="topic-query-filter">
        {{#if (and this.site.mobileView @canBulkSelect)}}
          <div class="topic-query-filter__bulk-action-btn">
            <BulkSelectToggle @bulkSelectHelper={{@bulkSelectHelper}} />
          </div>
        {{/if}}

        <div class="topic-query-filter__input">
          {{icon "filter" class="topic-query-filter__icon"}}
          <Input
            class="topic-query-filter__filter-term"
            @value={{this.newQueryString}}
            {{on "keydown" this.handleKeydown}}
            @type="text"
            id="queryStringInput"
            autocomplete="off"
            placeholder={{i18n "filter.placeholder"}}
            {{didInsert this.storeInputElement}}
          />
          {{#if this.newQueryString}}
            <DButton
              @icon="xmark"
              @action={{this.clearInput}}
              @disabled={{unless this.newQueryString "true"}}
              class="topic-query-filter__clear-btn btn-flat"
            />
          {{/if}}
          {{! EXPERIMENTAL OUTLET - don't use because it will be removed soon  }}
          <PluginOutlet
            @name="below-filter-input"
            @outletArgs={{lazyHash
              updateQueryString=this.updateQueryString
              newQueryString=this.newQueryString
            }}
          />
          <FilterTips
            @queryString={{this.newQueryString}}
            @onSelectTip={{this.updateQueryString}}
            @tips={{@tips}}
            @blockEnterSubmit={{this.blockEnterSubmit}}
            @inputElement={{this.inputElement}}
          />
        </div>
      </div>
    </section>
  </template>
}
