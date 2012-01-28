module Sideshow
    module Model
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
    end
end
