namespace :radiant do
  namespace :extensions do
    namespace :cache_by_page do
      
      desc "Runs the migration of the Cache By Page extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          CacheByPageExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          CacheByPageExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Page Options to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[CacheByPageExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(CacheByPageExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end  
    end
  end
end
