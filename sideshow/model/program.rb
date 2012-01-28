require "ken"
require "net/https"
require "uri"
require "json"

module Sideshow
    module Model
        class Program
            BULK_QUERY = {
                :mid => nil,
                :type => [],
                :name => nil
            }

            FILM_QUERY = {
                :initial_release_date => nil,
                :rating => [{
                    :mid => nil,
                    :name => nil,
                    :country => "United States of America",
                    :optional => true
                }],
                :runtime => [{
                    :runtime => nil,
                    :type_of_film_cut => nil,
                    :optional => true
                }],
                :genre => [{
                    :name => nil,
                    :optional => true
                }]
            }

            TV_QUERY = {
                :air_date_of_first_episode => nil,
                :air_date_of_final_episode => nil,
                :seasons => {
                    :return => "count",
                    :optional => true
                },
                :episodes => {
                    :return => "count",
                    :optional => true
                },
                :genre => [{
                    :name => nil,
                    :optional => true
                }]
            }

            def self.get(id)
                self.all([id])[0]
            end

            def self.all(ids)
                Ken.session.mqlread([{
                    :"mid|=" => ids,
                    :"type|=" => ["/film/film", "/tv/tv_program"]
                }.merge(BULK_QUERY)]).map do |data|
                    self.get_instance(data)
                end
            end

            def self.search(search)
                mql = {
                    :mid => nil,
                    :type => [],
                    :name => nil
                }
                uri = URI.parse("https://www.googleapis.com/freebase/v1/search?type=/film/film&type=/tv/tv_program&query=#{URI.encode_www_form_component(search)}&mql_output=#{URI.encode_www_form_component(mql.to_json)}")
                http = Net::HTTP.new(uri.host, uri.port)
                http.use_ssl = true
                http.verify_mode = OpenSSL::SSL::VERIFY_NONE

                request = Net::HTTP::Get.new(uri.request_uri)

                response = http.request(request)

                programs = JSON.parse(response.body)["result"].map do |r|
                    program = self.get_instance(r)
                    program["relevance:score"] = r["relevance:score"]
                    program
                end

                programs.sort do |a, b|
                    b["relevance:score"] <=> a["relevance:score"]
                end
            end

            def self.get_instance(data)
                Cache.get("program:#{data["mid"]}", 1..7 * 24 * 3600) do
                    data["type"] = data["type"].find do |t|
                        t == "/film/film" || t == "/tv/tv_program"
                    end

                    case data["type"]
                        when "/film/film"
                            details = Ken.session.mqlread({
                                :mid => data["mid"],
                                :type => data["type"]
                            }.merge(FILM_QUERY))

                            details["initial_release_date"] ||= "unknown"
                        when "/tv/tv_program"
                            details = Ken.session.mqlread({
                                :mid => data["mid"],
                                :type => data["type"]
                            }.merge(TV_QUERY))

                            details["air_date_of_first_episode"] ||= "unknown"
                            details["air_date_of_final_episode"] ||= "unknown"
                    end
                    Program.new(data.merge(details))
                end
            end

            def initialize(data)
                @data = data
            end

            def [](key)
                @data[key]
            end

            def []=(key, value)
                @data[key] = value
            end

            def type_label
                case @data["type"]
                    when "/film/film"
                        return "Movie"
                    when "/tv/tv_program"
                        return "TV Series"
                end
            end

            def article
                Cache.get("program:article:#{@data["mid"]}", 1..7 * 24 * 3600) do
                    uri = URI.parse("https://www.googleapis.com/freebase/v1/text#{@data["mid"]}?format=html")
                    http = Net::HTTP.new(uri.host, uri.port)
                    http.use_ssl = true
                    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

                    request = Net::HTTP::Get.new(uri.request_uri)

                    response = http.request(request)

                    JSON.parse(response.body)["result"]
                end
            end

            def movies
                Movie.all(:resource => @data["mid"], :order => [:priority.asc])
            end
        end
    end
end
