import { getOwner } from "@ember/owner";
import { hbs } from "ember-cli-htmlbars";
import $ from "jquery";
import { h } from "virtual-dom";
import { addWidgetCleanCallback } from "discourse/components/mount-widget";
import PostPlaceholder from "discourse/components/post/placeholder";
import discourseDebounce from "discourse/lib/debounce";
import { registerDeprecationHandler } from "discourse/lib/deprecated";
import { iconNode } from "discourse/lib/icon-library";
import { Placeholder } from "discourse/lib/posts-with-placeholders";
import { consolePrefix } from "discourse/lib/source-identifier";
import transformPost from "discourse/lib/transform-post";
import DiscourseURL from "discourse/lib/url";
import { avatarFor } from "discourse/widgets/post";
import RenderGlimmer from "discourse/widgets/render-glimmer";
import { createWidget } from "discourse/widgets/widget";
import { i18n } from "discourse-i18n";

export let havePostStreamWidgetExtensions = null;

registerDeprecationHandler((_, opts) => {
  if (opts?.id === "discourse.post-stream-widget-overrides") {
    if (!havePostStreamWidgetExtensions) {
      havePostStreamWidgetExtensions = new Set();
    }

    havePostStreamWidgetExtensions.add(consolePrefix().slice(1, -1));
  }
});

let transformCallbacks = null;

export function postTransformCallbacks(transformed) {
  if (transformCallbacks === null) {
    return;
  }

  for (let i = 0; i < transformCallbacks.length; i++) {
    transformCallbacks[i].call(this, transformed);
  }
}

export function addPostTransformCallback(callback) {
  transformCallbacks = transformCallbacks || [];
  transformCallbacks.push(callback);
}

let _enabled = true;
const DAY = 1000 * 60 * 60 * 24;

const _dontCloak = {};
let _cloaked = {};
let _heights = {};

export function disableCloaking() {
  _enabled = false;
}

export function preventCloak(postId) {
  _dontCloak[postId] = true;
}

export function cloak(post, component) {
  if (!_enabled || _cloaked[post.id] || _dontCloak[post.id]) {
    return;
  }

  const $post = $(`#post_${post.post_number}`).parent();
  _cloaked[post.id] = true;
  _heights[post.id] = $post.outerHeight();

  component.dirtyKeys.keyDirty(`post-${post.id}`);
  discourseDebounce(component, "queueRerender", 1000);
}

export function uncloak(post, component) {
  if (!_enabled || !_cloaked[post.id]) {
    return;
  }
  _cloaked[post.id] = null;
  component.dirtyKeys.keyDirty(`post-${post.id}`);
  component.queueRerender();
}

addWidgetCleanCallback("post-stream", () => {
  _cloaked = {};
  _heights = {};
});

// glimmer-post-stream: has glimmer version
createWidget("posts-filtered-notice", {
  buildKey: (attrs) => `posts-filtered-notice-${attrs.id}`,

  buildClasses() {
    return ["posts-filtered-notice"];
  },

  html(attrs) {
    const filters = attrs.streamFilters;

    if (filters.filter_upwards_post_id || filters.mixedHiddenPosts) {
      return [
        h(
          "span.filtered-replies-viewing",
          i18n("post.filtered_replies.viewing_subset")
        ),
        this.attach("filter-show-all", attrs),
      ];
    } else if (filters.replies_to_post_number) {
      const sourcePost = attrs.posts.findBy(
        "post_number",
        filters.replies_to_post_number
      );

      return [
        h(
          "span.filtered-replies-viewing",
          i18n("post.filtered_replies_viewing", {
            count: sourcePost.reply_count,
          })
        ),
        h("span.filtered-user-row", [
          h(
            "span.filtered-avatar",
            avatarFor.call(this, "small", {
              template: sourcePost.avatar_template,
              username: sourcePost.username,
              url: sourcePost.usernameUrl,
            })
          ),
          this.attach("filter-jump-to-post", {
            username: sourcePost.username,
            postNumber: filters.replies_to_post_number,
          }),
        ]),
        this.attach("filter-show-all", attrs),
      ];
    } else if (filters.filter && filters.filter === "summary") {
      return [
        h(
          "span.filtered-replies-viewing",
          i18n("post.filtered_replies.viewing_summary")
        ),
        this.attach("filter-show-all", attrs),
      ];
    } else if (filters.username_filters) {
      const firstUserPost = attrs.posts[1],
        userPostsCount = parseInt(attrs.filteredPostsCount, 10) - 1;
      return [
        h(
          "span.filtered-replies-viewing",
          i18n("post.filtered_replies.viewing_posts_by", {
            post_count: userPostsCount,
          })
        ),
        h(
          "span.filtered-avatar",
          avatarFor.call(this, "small", {
            template: firstUserPost.avatar_template,
            username: firstUserPost.username,
            url: firstUserPost.usernameUrl,
          })
        ),
        this.attach("poster-name", firstUserPost),
        this.attach("filter-show-all", attrs),
      ];
    }

    return [];
  },
});

// glimmer-post-stream: has glimmer version
createWidget("filter-jump-to-post", {
  tagName: "a.filtered-jump-to-post",
  buildKey: (attrs) => `jump-to-post-${attrs.id}`,

  html(attrs) {
    return i18n("post.filtered_replies.post_number", {
      username: attrs.username,
      post_number: attrs.postNumber,
    });
  },

  click() {
    DiscourseURL.jumpToPost(this.attrs.postNumber);
  },
});

// glimmer-post-stream: has glimmer version
createWidget("filter-show-all", {
  tagName: "button.filtered-replies-show-all",
  buildKey: (attrs) => `filtered-show-all-${attrs.id}`,

  buildClasses() {
    return ["btn", "btn-primary"];
  },

  html() {
    return [iconNode("up-down"), i18n("post.filtered_replies.show_all")];
  },

  click() {
    this.sendWidgetAction("cancelFilter");
    this.appEvents.trigger(
      "post-stream:filter-show-all",
      this.attrs.streamFilters
    );
  },
});

export default createWidget("post-stream", {
  tagName: "div.post-stream",

  html(attrs) {
    getOwner(this).lookup("service:site").useGlimmerPostStream;

    const posts = attrs.posts || [];
    const postArray = posts.toArray();
    const postArrayLength = postArray.length;
    const maxPostNumber =
      postArrayLength > 0 ? postArray[postArrayLength - 1].post_number : 0;
    const result = [];
    const before = attrs.gaps && attrs.gaps.before ? attrs.gaps.before : {};
    const after = attrs.gaps && attrs.gaps.after ? attrs.gaps.after : {};
    const mobileView = this.site.mobileView;

    let prevPost;
    let prevDate;

    for (let i = 0; i < postArrayLength; i++) {
      const post = postArray[i];

      if (post instanceof Placeholder) {
        this.site.useGlimmerPostStream
          ? new RenderGlimmer(
              this,
              "div.post-placeholder-shim",
              PostPlaceholder
            )
          : result.push(this.attach("post-placeholder"));
        continue;
      }

      const nextPost = i < postArray.length - 1 ? postArray[i + 1] : null;

      const transformed = transformPost(
        this.currentUser,
        this.site,
        post,
        prevPost,
        nextPost
      );
      transformed.canCreatePost = attrs.canCreatePost;
      transformed.prevPost = prevPost;
      transformed.nextPost = nextPost;
      transformed.mobileView = mobileView;

      if (transformed.canManage || transformed.canSplitMergeTopic) {
        transformed.multiSelect = attrs.multiSelect;

        if (attrs.multiSelect) {
          transformed.selected = attrs.selectedQuery(post);
        }
      }

      if (attrs.searchService) {
        transformed.highlightTerm = attrs.searchService.highlightTerm;
      }

      // Post gap - before
      const beforeGap = before[post.id];
      if (beforeGap) {
        result.push(
          this.site.useGlimmerPostStream
            ? new RenderGlimmer(
                this,
                "div.post-gap-shim",
                hbs`<Post::Gap @post={{@data.post}} @gap={{@data.gap}} @fillGap={{@data.fillGap}} />`,
                {
                  post,
                  gap: beforeGap,
                  fillGap: () =>
                    this.sendWidgetAction("fillGapBefore", {
                      post,
                      gap: beforeGap,
                    }),
                }
              )
            : this.attach(
                "post-gap",
                { pos: "before", postId: post.id, gap: beforeGap },
                { model: post }
              )
        );
      }

      // Handle time gaps
      const curTime = new Date(transformed.created_at).getTime();
      if (prevDate) {
        const daysSince = Math.floor((curTime - prevDate) / DAY);
        if (daysSince > this.siteSettings.show_time_gap_days) {
          result.push(
            new RenderGlimmer(
              this,
              "div.time-gap.small-action",
              hbs`<Post::TimeGap @daysSince={{@data.daysSince}} />`,
              { daysSince }
            )
          );
        }
      }
      prevDate = curTime;

      transformed.height = _heights[post.id];
      transformed.cloaked = _cloaked[post.id];

      postTransformCallbacks(transformed);

      if (transformed.isSmallAction) {
        result.push(
          this.site.useGlimmerPostStream
            ? new RenderGlimmer(
                this,
                "div.post-small-action-shim",
                hbs`<Post::SmallAction @post={{@data.post}}
                       @deletePost={{@data.deletePost}}
                       @editPost={{@data.editPost}}
                       @recoverPost={{@data.recoverPost}} />`,
                {
                  post,
                  deletePost: () => this.sendWidgetAction("deletePost", post),
                  editPost: () => this.sendWidgetAction("editPost", post),
                  recoverPost: () => this.sendWidgetAction("recoverPost", post),
                }
              )
            : this.attach("post-small-action", transformed, { model: post })
        );
      } else {
        if (this.site.useGlimmerPostStream) {
          let multiSelect, selected;
          if (post.canManage || post.canSplitMergeTopic) {
            multiSelect = attrs.multiSelect;

            if (multiSelect) {
              selected = attrs.selectedQuery(post);
            }
          }

          result.push(
            this.attach("glimmer-post", {
              post,
              prevPost,
              nextPost,
              canCreatePost: attrs.canCreatePost, //ok
              cancelFilter: (nearestPost) =>
                this.sendWidgetAction("cancelFilter", nearestPost),
              changeNotice: () => this.sendWidgetAction("changeNotice", post),
              changePostOwner: () =>
                this.sendWidgetAction("changePostOwner", post),
              deletePost: () => this.sendWidgetAction("deletePost", post),
              editPost: () => this.sendWidgetAction("editPost", post),
              expandHidden: () => this.sendWidgetAction("expandHidden", post),
              filteringRepliesToPostNumber: attrs.filteringRepliesToPostNumber,
              grantBadge: () => this.sendWidgetAction("grantBadge", post),
              lockPost: () => this.sendWidgetAction("lockPost", post),
              multiSelect,
              permanentlyDeletePost: () =>
                this.sendWidgetAction("permanentlyDeletePost", post),
              rebakePost: () => this.sendWidgetAction("rebakePost", post),
              recoverPost: () => this.sendWidgetAction("recoverPost", post),
              removeAllowedGroup: () =>
                this.sendWidgetAction("removeAllowedGroup", post),
              removeAllowedUser: () =>
                this.sendWidgetAction("removeAllowedUser", post),
              replyToPost: () => this.sendWidgetAction("replyToPost", post),
              selectBelow: () => this.sendWidgetAction("selectBelow", post),
              selectReplies: () => this.sendWidgetAction("selectReplies", post),
              selected,
              showFlags: () => this.sendWidgetAction("showFlags", post),
              showHistory: () => this.sendWidgetAction("showHistory", post),
              showInvite: () => this.sendWidgetAction("showInvite", post),
              showLogin: () => this.sendWidgetAction("showLogin", post),
              showPagePublish: () =>
                this.sendWidgetAction("showPagePublish", post),
              showRawEmail: () => this.sendWidgetAction("showRawEmail", post),
              showReadIndicator: attrs.showReadIndicator,
              togglePostSelection: () =>
                this.sendWidgetAction("togglePostSelection", post),
              togglePostType: () =>
                this.sendWidgetAction("togglePostType", post),
              toggleReplyAbove: () =>
                this.sendWidgetAction("toggleReplyAbove", post),
              toggleWiki: () => this.sendWidgetAction("toggleWiki", post),
              topicPageQueryParams: attrs.topicPageQueryParams,
              unhidePost: () => this.sendWidgetAction("unhidePost", post),
              unlockPost: () => this.sendWidgetAction("unlockPost", post),
              updateTopicPageQueryParams: () =>
                this.sendWidgetAction("updateTopicPageQueryParams"),
            })
          );
        } else {
          transformed.showReadIndicator = attrs.showReadIndicator;
          result.push(this.attach("post", transformed, { model: post }));
        }
      }

      // Post gap - after
      const afterGap = after[post.id];
      if (afterGap) {
        result.push(
          this.site.useGlimmerPostStream
            ? new RenderGlimmer(
                this,
                "div.post-gap-shim",
                hbs`<Post::Gap @post={{@data.post}} @gap={{@data.gap}} @fillGap={{@data.fillGap}} />`,
                {
                  post,
                  gap: afterGap,
                  fillGap: () =>
                    this.sendWidgetAction("fillGapAfter", {
                      post,
                      gap: afterGap,
                    }),
                }
              )
            : this.attach(
                "post-gap",
                { pos: "after", postId: post.id, gap: afterGap },
                { model: post }
              )
        );
      }

      if (
        i !== postArrayLength - 1 &&
        maxPostNumber <= attrs.highestPostNumber &&
        attrs.lastReadPostNumber === post.post_number
      ) {
        result.push(
          this.site.useGlimmerPostStream
            ? new RenderGlimmer(
                this,
                "div.post-visited-line-shim",
                hbs`<Post::VisitedLine @post={{@data.post}} />`,
                {
                  post,
                }
              )
            : this.attach("topic-post-visited-line", {
                post_number: post.post_number,
              })
        );
      }

      prevPost = post;
    }

    if (
      attrs.streamFilters &&
      Object.keys(attrs.streamFilters).length &&
      (Object.keys(before).length > 0 || Object.keys(after).length > 0)
    ) {
      result.push(
        this.site.useGlimmerPostStream
          ? new RenderGlimmer(
              this,
              "div.post-filtered-notice-shim",
              hbs`<Post::FilteredNotice @posts={{@data.posts}}
                     @cancelFilter={{@data.cancelFilter}}
                     @streamFilters={{@data.streamFilters}}
                     @filteredPostsCount={{@data.filteredPostsCount}} />`,
              {
                posts: postArray,
                streamFilters: attrs.streamFilters,
                filteredPostsCount: attrs.filteredPostsCount,
                cancelFilter: () => this.sendWidgetAction("cancelFilter"),
              }
            )
          : this.attach("posts-filtered-notice", {
              posts: postArray,
              streamFilters: attrs.streamFilters,
              filteredPostsCount: attrs.filteredPostsCount,
            })
      );
    }

    return result;
  },
});
