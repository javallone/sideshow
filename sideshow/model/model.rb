require "data_mapper"

require_relative "movie"
require_relative "setting"
require_relative "program"

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
    end
end
