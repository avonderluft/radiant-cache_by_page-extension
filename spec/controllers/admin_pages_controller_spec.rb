require File.dirname(__FILE__) + '/../spec_helper'

Admin::PagesController.module_eval { def rescue_action(e); raise e; end }

describe Admin::PagesController, 'with page options' do
  dataset :users_and_pages

  before :each do
    controller.cache.clear
    @page = pages(:home)
  end

  [:admin, :developer].each do |user|
     it "should display the admin edit page successfully for #{user}" do
       login_as user
       get :edit, :id => @page
       response.should be_success
       response.should render_template('edit')
       logout
     end
  end

end
