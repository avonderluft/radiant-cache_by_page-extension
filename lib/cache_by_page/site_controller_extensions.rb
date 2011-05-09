module CacheByPage::SiteControllerExtensions
  def self.included(base)
    base.class_eval do
      alias_method_chain :set_cache_control, :cache_by_page
    end
  end
  
  private
  
  def set_cache_control_with_cache_by_page
    if (request.head? || request.get?) && @page.cache? && @page.cache_duration && live?
      expires_in @page.cache_duration, :public => true, :private => false
    else
      set_cache_control_without_cache_by_page
    end
  end

end