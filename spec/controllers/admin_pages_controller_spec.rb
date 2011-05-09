require File.dirname(__FILE__) + '/../spec_helper'

Admin::PagesController.module_eval { def rescue_action(e); raise e; end }

describe Admin::PagesController, 'with cache_by_page' do
  dataset :users_and_pages
  integrate_views

  before :each do
    @page = pages(:home)
  end

  [:admin, :non_admin, :designer].each do |user|
    describe "privileges for user '#{user}'" do
      before(:each) do
        login_as user
      end
      it "should display admin edit page on a new page" do
        get :new
        response.should render_template('new')
      end
      if user == :admin
        it "should display page caching options on the admin edit page for an existing page" do
          get :edit, :id => @page
          response.should include_text("Cache this page for")
        end
      else
        it "should not display page caching options on the admin edit page for an existing page" do
          get :edit, :id => @page
          response.should_not include_text("Cache this page for")
        end
      end
    end
  end

  after :each do
    response.should be_success
    logout
  end

end
