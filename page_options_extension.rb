# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class PageOptionsExtension < Radiant::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/page_options"
  
  # define_routes do |map|
  #   map.connect 'admin/page_options/:action', :controller => 'admin/page_options'
  # end
  
  def activate
    # admin.tabs.add "Page Options", "/admin/page_options", :after => "Layouts", :visibility => [:all]
  end
  
  def deactivate
    # admin.tabs.remove "Page Options"
  end
  
end