import Component from "@ember/component";
import { htmlSafe } from "@ember/template";
import {
  attributeBindings,
  classNameBindings,
} from "@ember-decorators/component";
import $ from "jquery";
import TopicPostBadges from "discourse/components/topic-post-badges";
import formatAge from "discourse/helpers/format-age";
import raw from "discourse/helpers/raw";

@classNameBindings(":featured-topic")
@attributeBindings("topic.id:data-topic-id")
export default class FeaturedTopic extends Component {
  click(e) {
    if (e.target.closest(".last-posted-at")) {
      this.appEvents.trigger("topic-entrance:show", {
        topic: this.topic,
        position: $(e.target).offset(),
      });
      return false;
    }
  }

  <template>
    {{raw "topic-status" topic=this.topic}}
    <a href={{this.topic.lastUnreadUrl}} class="title">{{htmlSafe
        this.topic.fancyTitle
      }}</a>
    <TopicPostBadges
      @unreadPosts={{this.topic.unread_posts}}
      @unseen={{this.topic.unseen}}
      @url={{this.topic.lastUnreadUrl}}
    />

    <a href={{this.topic.lastPostUrl}} class="last-posted-at">{{formatAge
        this.topic.last_posted_at
      }}</a>
  </template>
}
