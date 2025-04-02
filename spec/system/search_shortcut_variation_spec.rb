# frozen_string_literal: true

describe "Search | Shortcuts for variations of search input", type: :system do
  fab!(:current_user) { Fabricate(:user) }

  let(:welcome_banner) { PageObjects::Components::WelcomeBanner.new }
  let(:search_page) { PageObjects::Pages::Search.new }

  before { sign_in(current_user) }

  context "when search_experience is search_field" do
    before { SiteSetting.search_experience = "search_field" }

    context "when enable_welcome_banner is true" do
      before { SiteSetting.enable_welcome_banner = true }

      it "displays and focuses welcome banner search when / is pressed and hides it when Escape is pressed" do
        visit("/")
        expect(welcome_banner).to be_visible
        page.send_keys("/")
        expect(search_page).to have_search_menu
        expect(current_active_element[:id]).to eq("welcome-banner-search-input")
        page.send_keys(:escape)
        expect(search_page).to have_no_search_menu_visible
      end

      it "displays and focuses welcome banner search when Ctrl+F is pressed and hides it when Escape is pressed" do
        visit("/")
        expect(welcome_banner).to be_visible
        search_page.browser_search_shortcut
        expect(search_page).to have_search_menu
        expect(current_active_element[:id]).to eq("welcome-banner-search-input")
        page.send_keys(:escape)
        expect(search_page).to have_no_search_menu_visible
      end

      it "displays and focuses welcome banner search when Ctrl+F is pressed and blurs it when Ctrl+F is pressed" do
        visit("/")
        expect(welcome_banner).to be_visible
        search_page.browser_search_shortcut
        expect(search_page).to have_search_menu
        expect(current_active_element[:id]).to eq("welcome-banner-search-input")
        # NOTE: This does not work as expected because pressing Ctrl+F in the browser does
        # not change the document acive element, leaving it here as a reminder to manually test
        # this behavior.
        # search_page.browser_search_shortcut
        # expect(current_active_element[:id]).to eq(nil)
      end

      context "when welcome banner is not in the viewport" do
        before do
          visit("/")
          fake_scroll_down_long
        end

        it "displays and focuses header search when / is pressed and hides it when Escape is pressed" do
          expect(welcome_banner).to be_invisible
          page.send_keys("/")
          expect(search_page).to have_search_menu
          expect(current_active_element[:id]).to eq("header-search-input")
          page.send_keys(:escape)
          expect(search_page).to have_no_search_menu_visible
        end

        it "displays and focuses header search when Ctrl+F is pressed and hides it when Escape is pressed" do
          expect(welcome_banner).to be_invisible
          search_page.browser_search_shortcut
          expect(search_page).to have_search_menu
          expect(current_active_element[:id]).to eq("header-search-input")
          page.send_keys(:escape)
          expect(search_page).to have_no_search_menu_visible
        end

        it "displays and focuses welcome banner search when Ctrl+F is pressed and blurs it when Ctrl+F is pressed" do
          expect(welcome_banner).to be_invisible
          search_page.browser_search_shortcut
          expect(search_page).to have_search_menu
          expect(current_active_element[:id]).to eq("header-search-input")
          # NOTE: This does not work as expected because pressing Ctrl+F in the browser does
          # not change the document acive element, leaving it here as a reminder to manually test
          # this behavior.
          # search_page.browser_search_shortcut
          # expect(current_active_element[:id]).to eq(nil)
        end
      end
    end

    context "when enable_welcome_banner is false" do
      before { SiteSetting.enable_welcome_banner = false }

      it "displays and focuses header search when / is pressed and hides it when Escape is pressed" do
        visit("/")
        expect(welcome_banner).to be_hidden
        page.send_keys("/")
        expect(search_page).to have_search_menu
        expect(current_active_element[:id]).to eq("header-search-input")
        page.send_keys(:escape)
        expect(search_page).to have_no_search_menu_visible
      end

      it "displays and focuses header search when Ctrl+F is pressed and hides it when Escape is pressed" do
        visit("/")
        expect(welcome_banner).to be_hidden
        search_page.browser_search_shortcut
        expect(search_page).to have_search_menu
        expect(current_active_element[:id]).to eq("header-search-input")
        page.send_keys(:escape)
        expect(search_page).to have_no_search_menu_visible
      end
    end
  end

  context "when search_experience is search_icon" do
    before { SiteSetting.search_experience = "search_icon" }

    context "when enable_welcome_banner is true" do
      before { SiteSetting.enable_welcome_banner = true }

      it "displays and focuses welcome banner search when / is pressed and hides it when Escape is pressed" do
        visit("/")
        expect(welcome_banner).to be_visible
        page.send_keys("/")
        expect(search_page).to have_search_menu
        expect(current_active_element[:id]).to eq("welcome-banner-search-input")
        page.send_keys(:escape)
        expect(search_page).to have_no_search_menu_visible
      end

      it "displays and focuses welcome banner search when Ctrl+F is pressed and hides it when Escape is pressed" do
        visit("/")
        expect(welcome_banner).to be_visible
        search_page.browser_search_shortcut
        expect(search_page).to have_search_menu
        expect(current_active_element[:id]).to eq("welcome-banner-search-input")
        page.send_keys(:escape)
        expect(search_page).to have_no_search_menu_visible
      end

      it "displays and focuses welcome banner search when Ctrl+F is pressed and blurs it when Ctrl+F is pressed" do
        visit("/")
        expect(welcome_banner).to be_visible
        search_page.browser_search_shortcut
        expect(search_page).to have_search_menu
        expect(current_active_element[:id]).to eq("welcome-banner-search-input")

        # NOTE: This does not work as expected because pressing Ctrl+F in the browser does
        # not change the document acive element, leaving it here as a reminder to manually test
        # this behavior.
        # search_page.browser_search_shortcut
        # expect(current_active_element[:id]).to eq(nil)
      end

      context "when welcome banner is not in the viewport" do
        before do
          visit("/")
          fake_scroll_down_long
        end

        it "displays and focuses search icon search when / is pressed and hides it when Escape is pressed" do
          expect(welcome_banner).to be_invisible
          page.send_keys("/")
          expect(search_page).to have_search_menu
          expect(current_active_element[:id]).to eq("icon-search-input")
          page.send_keys(:escape)
          expect(search_page).to have_no_search_menu_visible
        end
      end
    end

    context "when enable_welcome_banner is false" do
      before { SiteSetting.enable_welcome_banner = false }

      it "displays and focuses search icon search when / is pressed and hides it when Escape is pressed" do
        visit("/")
        expect(welcome_banner).to be_hidden
        page.send_keys("/")
        expect(search_page).to have_search_menu
        expect(current_active_element[:id]).to eq("icon-search-input")
        page.send_keys(:escape)
        expect(search_page).to have_no_search_menu_visible
      end

      # This search menu only shows within a topic, not in other pages on the site,
      # unlike header search which is always visible.
      context "when within a topic with 20+ posts" do
        fab!(:topic)
        fab!(:posts) { Fabricate.times(21, :post, topic: topic) }

        it "opens search on first press of Ctrl+F, and closes on the second" do
          visit "/t/#{topic.slug}/#{topic.id}"
          search_page.browser_search_shortcut
          expect(search_page).to have_search_menu_visible
          expect(current_active_element[:id]).to eq("icon-search-input")
          # NOTE: This does not work as expected because pressing Ctrl+F in the browser does
          # not change the document acive element, leaving it here as a reminder to manually test
          # this behavior.
          # search_page.browser_search_shortcut
          # expect(current_active_element[:id]).to eq(nil)
        end
      end
    end
  end
end
