module PageOptions::PageExtensions
  
  Page.class_eval do
    def cache?
     self.nocache? == false
    end
  end
  
end