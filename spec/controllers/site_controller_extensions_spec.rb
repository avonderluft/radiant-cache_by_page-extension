require 'spec_helper'
require 'site_controller'

SiteController.module_eval { def rescue_action(e); raise e; end }

describe SiteController, "(Extended) - cache by page changes" do

  it "should include the extension module" do
    SiteController.included_modules.should include(CacheByPage::SiteControllerExtensions)
  end
  
  describe "alias method chain" do
    it "should be set up" do
      controller.private_methods.should include('set_cache_control_with_cache_by_page')
      controller.private_methods.should include('set_cache_control_without_cache_by_page')
      controller.private_methods.should include('set_cache_control')
    end
  end

end
