require "data_mapper"

module Sideshow
    module Model
        def self.init(db)
            DataMapper.setup(:default, db)
            DataMapper.finalize
            DataMapper.auto_upgrade!

            if Setting.get(:cache_prefix).nil?
                Setting.set(:cache_prefix, "default")
            end

            if Setting.get(:player_cmd).nil?
                Setting.set(:player_cmd, "/usr/bin/mplayer -fs -slave -quiet dvdnav:///%DVD_IMAGE%")
            end
        end

        class Movie
            include DataMapper::Resource

            storage_names[:default] = "movies"

            property :id, Serial
            property :priority, Integer, :default => 0
            property :description, String
            property :file, String, :length => 255, :unique => true
            property :resource, String, :length => 255

            def self.loadFiles(root)
                media_glob = File.join(root, "*.iso")
                Dir.glob(media_glob).each do |file|
                    Movie.create(:file => file.sub(root, "").sub(/^\//, ""))
                end
            end

            def self.unassociated
                Movie.all(:resource => nil, :order => [:file.asc])
            end
        end

        class Setting
            include DataMapper::Resource

            storage_names[:default] = "settings"

            property :name, String, :unique => true, :key => true
            property :value, String, :length => 255

            def self.getAll()
                result = {}
                Setting.all.each do |s|
                    result[s.name.to_sym] = s.value
                end

                result
            end

            def self.get(name)
                s = Setting.first(:name => name.to_s)
                s.value unless s.nil?
            end

            def self.set(name, value)
                s = Setting.first_or_create(:name => name.to_s)
                s.value = value
                s.save
            end
        end
    end
end
