# frozen_string_literal: true

module PageObjects
  module Components
    class Post < PageObjects::Components::Base
      def initialize(post_number)
        @post_number = post_number
      end

      def post
        find("#post_#{@post_number}")
      end

      def reply
        post.find(".reply.create").click
      end

      def edit
        post.find(".show-more-actions").click
        post.find("button.edit").click
      end

      def show_replies
        post.find(".show-replies").click
      end

      def load_more_replies
        find("#embedded-posts__bottom--#{@post_number} .load-more-replies").click
      end

      def has_replies?(count: nil)
        find("#embedded-posts__bottom--#{@post_number}").has_css?(".reply", count:)
      end

      def has_more_replies?
        find("#embedded-posts__bottom--#{@post_number}").has_css?(".load-more-replies")
      end

      def has_loaded_all_replies?
        find("#embedded-posts__bottom--#{@post_number}").has_no_css?(".load-more-replies")
      end

      def show_parent_posts
        post.find(".reply-to-tab").click
      end

      def has_parent_posts?(count: nil)
        find("#embedded-posts__top--#{@post_number}").has_css?(".reply", count:)
      end

      def has_no_parent_post_content?(content)
        find("#embedded-posts__top--#{@post_number}").has_no_content?(content)
      end
    end
  end
end
