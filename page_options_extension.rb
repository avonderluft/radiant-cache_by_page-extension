# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application_controller'

class PageOptionsExtension < Radiant::Extension
  version "1.0"
  description "Enables per page options, such as setting cache expire time, or turning off caching for a single page"
  url "https://github.com/avonderluft/radiant-page_options-extension"

  def activate
    Page.send :include, PageOptions::PageExtensions
    admin.page.index.add :sitemap_head, 'caching_th', :before => 'status_column_header'
    admin.page.index.add :node, 'caching_td', :before => 'status_column'
    admin.page.edit.add :extended_metadata, 'caching_meta'
  end

end