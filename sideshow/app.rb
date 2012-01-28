#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"

require "sinatra/base"

require "net/https"
require "uri"

require_relative "cache"
require_relative "model/model"

module Sideshow
    class App < Sinatra::Base
        def self.init()
            Cache.setup(Model::Setting.get(:cache_server), Model::Setting.get(:cache_prefix))

            media_root = Model::Setting.get(:media_root)
            unless media_root.nil? or media_root.empty?
                Model::Movie.loadFiles(media_root)
            end

            if Cache.enabled?
                resource_ids = Model::Movie.all(:fields => [:resource],
                    :unique => true,
                    :order => nil,
                    :resource.not => nil
                ).map do |m|
                    m.resource
                end

                Model::Program.all(resource_ids)
            end
        end

        helpers do
            def resource_url(resource)
                "/program#{resource["mid"]}"
            end

            def image_tag(resource, height)
                url = "/image/#{height}#{resource["mid"]}"
                "<img src=\"#{url}\" alt=\"#{resource["name"]}\" />"
            end

            def format_date(date, format="%b %e, %Y")
                begin
                    t = Time.parse(date)
                    t.strftime(format)
                rescue
                    date
                end
            end
        end

        get "/" do
            Cache.get("page:program_list", 24 * 3600) do
                movies = Model::Movie.all(:fields => [:resource], :unique => true, :order => nil, :resource.not => nil)
                programs = []

                if movies.length > 0
                    resource_ids = movies.map do |m|
                        m.resource
                    end
                    programs = Model::Program.all(resource_ids).sort_by do |i|
                        i["name"].sub(/(^the)\s(.*)$/i, "\\2, \\1")
                    end
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
            movie = Model::Movie.get(params[:media])
            priority = Model::Movie.max(:priority, :conditions => ['resource = ?', params[:resource]]) || 0

            movie.resource = params[:resource]
            movie.description = params[:description]
            movie.priority = priority + 1
            movie.save

            Cache.evict("program:#{params[:resource]}")
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
                results = Model::Program.search(params[:search])
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
            program = Model::Program.get(id)

            erb :program, :locals => {
                :title => program["name"],
                :active => "",
                :content_class => "program",
                :program => program,
                :movies => program.movies
            }
        end

        get %r{/movies(/.+)} do |id|
            program = Model::Program.get(id)

            erb :movie_list, :layout => false, :locals => {
                :program => program,
                :movies => program.movies
            }
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
