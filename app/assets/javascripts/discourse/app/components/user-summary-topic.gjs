import Component from "@ember/component";
import { hash } from "@ember/helper";
import { htmlSafe } from "@ember/template";
import { tagName } from "@ember-decorators/component";
import PluginOutlet from "discourse/components/plugin-outlet";
import icon from "discourse/helpers/d-icon";
import formatDate from "discourse/helpers/format-date";
import number from "discourse/helpers/number";

@tagName("li")
export default class UserSummaryTopic extends Component {
  <template>
    <PluginOutlet
      @name="user-summary-topic-wrapper"
      @outletArgs={{hash topic=@topic url=@url}}
    >
      <span class="topic-info">
        {{formatDate @createdAt format="tiny" noTitle="true"}}
        {{#if @likes}}
          &middot;
          {{icon "heart"}}&nbsp;<span class="like-count">{{number
              @likes
            }}</span>
        {{/if}}
      </span>
      <br />
      <a href={{@url}}>{{htmlSafe @topic.fancyTitle}}</a>
    </PluginOutlet>
  </template>
}
