require "sinatra/base"

require_relative "../mplayer/mplayer"
require_relative "model"

module Sideshow
    class Controller < Sinatra::Base
        def self.mplayer
            @mplayer ||= nil
        end

        def self.mplayer=(mplayer)
            @mplayer = mplayer
        end

        get "/play" do
            movie = Model::Movie.get(params[:id])
            root = Model::Setting.get(:media_root)

            Controller.mplayer.stop unless Controller.mplayer.nil?

            Controller.mplayer = Mplayer::Control.new(Model::Setting.get(:player_cmd))
            Controller.mplayer.open(File.join(root, movie.file))
            status 201
        end

        get "/pause" do
            Controller.mplayer.pause unless Controller.mplayer.nil?
            status 201
        end

        get "/stop" do
            Controller.mplayer.stop unless Controller.mplayer.nil?
            Controller.mplayer = nil
            status 201
        end

        get "/up" do
            Controller.mplayer.nav :up unless Controller.mplayer.nil?
            status 201
        end

        get "/down" do
            Controller.mplayer.nav :down unless Controller.mplayer.nil?
            status 201
        end

        get "/left" do
            Controller.mplayer.nav :left unless Controller.mplayer.nil?
            status 201
        end

        get "/right" do
            Controller.mplayer.nav :right unless Controller.mplayer.nil?
            status 201
        end

        get "/select" do
            Controller.mplayer.nav :select unless Controller.mplayer.nil?
            status 201
        end

        get "/menu" do
            Controller.mplayer.nav :menu unless Controller.mplayer.nil?
            status 201
        end

        get "/chapter_back" do
            Controller.mplayer.seek_chapter(-1) unless Controller.mplayer.nil?
            status 201
        end

        get "/chapter_fwd" do
            Controller.mplayer.seek_chapter(1) unless Controller.mplayer.nil?
            status 201
        end

        get "/skip_back" do
            Controller.mplayer.seek(-30) unless Controller.mplayer.nil?
            status 201
        end

        get "/skip_fwd" do
            Controller.mplayer.seek(30) unless Controller.mplayer.nil?
            status 201
        end
    end
end
