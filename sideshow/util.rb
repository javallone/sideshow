require "net/https"
require "uri"
require "json"

module Sideshow
    class Util
        def self.resource_url(resource)
            "/program#{resource.id}"
        end

        def self.image_tag(resource, height)
            url = "/image/#{height}#{resource.id}"
            "<img src=\"#{url}\" alt=\"#{resource.name}\" />"
        end

        def self.get_article(resource)
            uri = URI.parse("https://www.googleapis.com/freebase/v1/text#{resource.id}?format=html")
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE

            request = Net::HTTP::Get.new(uri.request_uri)

            response = http.request(request)

            JSON.parse(response.body)["result"]
        end

        def self.format_date(date, format="%b %e, %Y")
            begin
                t = Time.parse(date)
                t.strftime(format)
            rescue
                date
            end
        end

        def self.resource_type(resource)
            type = "film" unless resource.type("/film/film").nil?
            type = "tv" unless resource.type("/tv/tv_program").nil?

            return type
        end

        def self.resource_type_label(type)
            case type
                when "film"
                    return "Movie"
                when "tv"
                    return "TV Series"
            end
        end

        def self.program_info(opts = {})
            program = opts[:program].nil? ? nil : opts[:program]
            id = opts[:id].nil? ? program.id : opts[:id]

            Cache.get("program:#{id}", 1..7 * 24 * 3600) do
                program = Ken.get(id) if program.nil?
                type = self.resource_type(program)

                info = {
                    :program => program,
                    :label => program.name,
                    :summary => self.get_article(program),
                    :type => self.resource_type_label(type),
                    :release_year => nil,
                    :details => {},
                    :movies => Model::Movie.all(:resource => program.id, :order => [:priority.asc])
                }

                case type
                    when "film"
                        released = program.attribute("/film/film/initial_release_date")
                        info[:details]["Released"] = self.format_date(released.values[0]) unless released.nil?
                        info[:release_year] = self.format_date(released.values[0], "%Y") unless released.nil?

                        rating = program.attribute("/film/film/rating")
                        info[:details]["Rating"] = self.image_tag(rating.values[0], 20) unless rating.nil?

                        film_runtime = program.attribute("/film/film/runtime")
                        unless film_runtime.nil?
                            cut_runtime = film_runtime.values[0].attribute("/film/film_cut/runtime")
                            unless cut_runtime.nil?
                                runtime = cut_runtime.values[0].to_i
                                info[:details]["Runtime"] = "#{runtime / 60}h#{runtime % 60}m"
                            end
                        end

                        genres = program.attribute("/film/film/genre")
                        unless genres.nil?
                            genre_items = genres.values.map {|g| "<li>#{g.name}</li>" }
                            info[:details]["Genres"] = "<ul>#{genre_items.join('')}</ul>"
                        end
                    when "tv"
                        first_episode = program.attribute("/tv/tv_program/air_date_of_first_episode")
                        first_episode_date = first_episode.nil? ? "unknown" : first_episode.values[0]

                        final_episode = program.attribute("/tv/tv_program/air_date_of_final_episode")
                        final_episode_date = final_episode.nil? ? "unknown" : final_episode.values[0]

                        info[:details]["Aired"] = "#{self.format_date(first_episode_date)} - #{self.format_date(final_episode_date)}"
                        info[:release_year] = "#{self.format_date(first_episode_date, "%Y")} - #{self.format_date(final_episode_date, "%Y")}"

                        seasons = program.attribute("/tv/tv_program/seasons")
                        info[:details]["Seasons"] = seasons.values.length unless seasons.nil?

                        episodes = program.attribute("/tv/tv_program/episodes")
                        info[:details]["Episodes"] = episodes.values.length unless episodes.nil?

                        genres = program.attribute("/tv/tv_program/genre")
                        unless genres.nil?
                            genre_items = genres.values.map {|g| "<li>#{g.name}</li>" }
                            info[:details]["Genres"] = "<ul>#{genre_items.join('')}</ul>"
                        end
                end

                info
            end
        end
    end
end
