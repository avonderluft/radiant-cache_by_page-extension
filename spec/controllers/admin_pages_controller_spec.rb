require File.dirname(__FILE__) + '/../spec_helper'

Admin::PagesController.module_eval { def rescue_action(e); raise e; end }

describe Admin::PagesController, 'with page options' do
  dataset :users_and_pages

  before :each do
    controller.cache.clear
    @page = pages(:home)
  end

  [:admin, :developer].each do |user|
     it "should display the admin edit page successfully for #{user} on an existing page" do
       login_as user
       get :edit, :id => @page
       response.should render_template('edit')
     end

     it "should display admin edit page successfully for #{user} on a new page" do
       login_as user
       get :new
       response.should render_template('new')
     end
  end

  after :each do
    response.should be_success
    logout
  end

end
