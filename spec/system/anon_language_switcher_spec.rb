# frozen_string_literal: true

RSpec.describe "Anonymous user language switcher", type: :system do
  SWITCHER_SELECTOR = "button[data-identifier='language-switcher']"

  let(:topic_page) { PageObjects::Pages::Topic.new }
  let(:switcher) { PageObjects::Components::DMenu.new(SWITCHER_SELECTOR) }

  fab!(:japanese_user) { Fabricate(:user, locale: "ja") }
  fab!(:topic) do
    topic = Fabricate(:topic, title: "Life strategies from The Art of War")
    Fabricate(:post, topic:)
    topic
  end

  before do
    SiteSetting.allow_user_locale = true
    SiteSetting.set_locale_from_cookie = true
  end

  it "only shows the language switcher based on what is in target languages" do
    SiteSetting.experimental_content_localization_supported_locales = "es|ja"

    SiteSetting.experimental_anon_language_switcher = false
    visit("/")

    expect(page).not_to have_css(SWITCHER_SELECTOR)

    SiteSetting.experimental_anon_language_switcher = true
    visit("/")

    switcher.expand
    expect(switcher).to have_content("日本語")
    expect(switcher).to have_content("Español")

    SiteSetting.experimental_content_localization_supported_locales = "es"
    visit("/")

    switcher.expand
    expect(switcher).not_to have_content("日本語")

    sign_in(japanese_user)
    expect(page).not_to have_css(SWITCHER_SELECTOR)
  end
end
