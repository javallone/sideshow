#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"

require "sinatra/base"

require "ken"
require "amatch"

require "net/https"
require "uri"

require_relative "cache"
require_relative "util"
require_relative "model"

module Sideshow
    class App < Sinatra::Base
        def self.init()
            Cache.setup(Model::Setting.get(:cache_server), Model::Setting.get(:cache_prefix))

            media_root = Model::Setting.get(:media_root)
            unless media_root.nil? or media_root.empty?
                Model::Movie.loadFiles(media_root)
            end

            if Cache.enabled?
                Model::Movie.all(:fields => [:resource], :unique => true, :order => nil, :resource.not => nil).each do |m|
                    Util.program_info(:id => m.resource)
                end
            end
        end

        helpers do
            def resource_url(resource)
                Util.resource_url(resource)
            end

            def image_tag(resource, height)
                Util.image_tag(resource, height)
            end
        end

        get "/" do
            Cache.get("page:program_list", 24 * 3600) do
                movies = Model::Movie.all(:fields => [:resource], :unique => true, :order => nil, :resource.not => nil)
                programs = []

                if movies.length > 0
                    programs = movies.map do |m|
                        Util.program_info(:id => m.resource)
                    end

                    programs.sort_by! { |i| i[:label].sub(/(^the)\s(.*)$/i, "\\2, \\1") }
                end

                erb :index, :locals => {
                    :title => "Movies",
                    :active => "list",
                    :content_class => "movies",
                    :programs => programs,
                    :unassociated => Model::Movie.unassociated
                }
            end
        end

        get "/add" do
            erb :add, :layout => :dialog_layout, :locals => {
                :title => "Add Media",
                :content_class => "add",
                :resource => params[:resource],
                :unassociated => Model::Movie.unassociated
            }
        end

        get "/doAdd" do
            resource = Ken.get(params[:resource])

            movie = Model::Movie.get(params[:media])
            priority = Model::Movie.max(:priority, :conditions => ['resource = ?', resource.id]) or 0

            movie.resource = resource.id
            movie.description = params[:description]
            movie.priority = priority + 1
            movie.save

            Cache.evict("program:#{resource.id}")
            Cache.evict("page:program_list")

            status 201
        end

        get "/search" do
            Cache.get("page:search", 24 * 3600) do
                erb :search, :locals => {
                    :title => "Search",
                    :active => "search",
                    :content_class => "search"
                }
            end
        end

        get "/doSearch" do
            results = []
            unless params[:search].nil?
                name_matches = Ken.all("name~=" => params[:search], "type|=" => ["/film/film", "/tv/tv_program"])
                alias_matches = Ken.all("/common/topic/alias~=" => params[:search], "type|=" => ["/film/film", "/tv/tv_program"])

                results.concat(name_matches)
                results.concat(alias_matches)
                results.uniq! { |r| r.id }

                matcher = Amatch::Levenshtein.new(params[:search])

                results.map! do |r|
                    names = [r.name]
                    aliases = r.attribute("/common/topic/alias")
                    names.concat(aliases.values) unless aliases.nil?

                    { :distance => matcher.match(names).min }.merge(Util.program_info(:program => r))
                end

                results.sort! do |a, b|
                    value = a[:distance] <=> b[:distance]
                    if value == 0
                        value = a[:label] <=> b[:label]
                    end
                    value
                end
            end

            erb :search_results, :layout => false, :locals => {
                :results => results
            }
        end

        get "/settings" do
            Cache.get("page:settings", 24 * 3600) do
                erb :settings, :layout => :dialog_layout, :locals => {
                    :title => "Settings",
                    :content_class => "settings",
                    :media_root => "",
                    :cache_server => ""
                }.merge(Model::Setting.getAll)
            end
        end

        get "/updateSettings" do
            old_values = Model::Setting.getAll
            cache_reconnect = false

            params.each do |k, v|
                Model::Setting.set(k, v)

                if k == "media_root" and v != old_values[:media_root]
                    Model::Movie.loadFiles(v)
                end

                if k == "cache_server" and v != old_values[:cache_server]
                    cache_reconnect = true
                end

                if k == "cache_prefix" and v != old_values[:cache_prefix]
                    cache_reconnect = true
                end
            end

            Cache.setup(Model::Setting.get(:cache_server), Model::Setting.get(:cache_prefix)) if cache_reconnect

            Cache.evict("page:settings")

            status 201
        end

        get "/refresh" do
            root = Model::Setting.get(:media_root)
            Model::Movie.loadFiles(root)

            Cache.evict("page:program_list")

            status 201
        end

        get "/flush" do
            Cache.flush

            status 201
        end

        get "/remote" do
            Cache.get("page:remote", 24 * 3600) do
                erb :remote, :layout => :dialog_layout, :locals => {
                    :title => "Remote",
                    :content_class => "remote"
                }
            end
        end

        get %r{/program(/.+)} do |id|
            info = Util.program_info(:id => id)

            erb :program, :locals => {
                :title => info[:label],
                :active => "",
                :content_class => "program"
            }.merge(info)
        end

        get %r{/movies(/.+)} do |id|
            erb :movie_list, :layout => false, :locals => Util.program_info(:id => id)
        end

        get %r{/image/(\d+)(/.+)} do |size, id|
            begin
                data = Cache.get("image:#{id}@#{size}", 1..7 * 24 * 3600) do
                    uri = URI.parse("https://usercontent.googleapis.com/freebase/v1/image#{id}?mode=fit&maxheight=#{size}")
                    http = Net::HTTP.new(uri.host, uri.port)
                    http.use_ssl = true
                    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

                    request = Net::HTTP::Get.new(uri.request_uri)

                    response = http.request(request)

                    raise "Request Fail" unless response.is_a? Net::HTTPSuccess

                    data = {
                        :headers => { "Content-Type" => response.content_type },
                        :content => response.body
                    }
                end

                headers data[:headers]
                data[:content]
            rescue RuntimeError => e
                if e.message == "Request Fail"
                    status 500
                else
                    raise
                end
            end
        end

        run! if app_file == $0
    end
end
