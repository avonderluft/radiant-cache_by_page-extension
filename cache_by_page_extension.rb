# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application_controller'

class CacheByPageExtension < Radiant::Extension
  version "#{File.read(File.expand_path(File.dirname(__FILE__)) + '/VERSION')}"
  description "Enables per page option of setting cache expire time, or turning off caching for a single page"
  url "https://github.com/avonderluft/radiant-cache_by_page-extension"

  def activate
    SiteController.send :include, CacheByPage::SiteControllerExtensions
    Page.send :include, CacheByPage::PageExtensions
    admin.page.index.add :sitemap_head, 'caching_th', :before => 'status_column_header'
    admin.page.index.add :node, 'caching_td', :before => 'status_column'
    admin.page.edit.add :extended_metadata, 'caching_meta'
  end

end