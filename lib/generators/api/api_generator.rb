module ApiGearsRails
  module Generators
    class ApiGenerator < Rails::Generators::Base

      def initialize(*args)
        @base = args[0][0]
        @url = args[0][1]
        # if(@base.nil?)
        #
        # end
        super(*args)
      end
      source_root File.expand_path('templates', __dir__)
      # include Rails::Generators::ResourceHelpers
      # include Rails::Generators::Migration
      include GeneratorHelpers

      desc "Installs boilerplate for an implementation of ApiGears"

      def generate_api
        if(!File.exist?("app/lib/#{api_filename}"))
          template "api.rb", File.join("app/lib", api_filename)
        end
      end

      private
      def name
        api_classname
      end
      def api_filename
        "#{@base.underscore}.rb"
      end
      def api_classname
        @base.camelcase
      end
      def api_url
        if(@url.present?)
          if(@url.match(/\{([a-zA-Z_0-9\-]*)\}/))
            url_args = @url.match(/\{([a-zA-Z_0-9\-]*)\}/).captures
            url_args.each do |argName|
              @url = @url.gsub("{#{argName}}",'#{'+argName+'}')
            end
          end
          @url = 'url = "'+@url+'" # The base url that will be used to query the api.'
        else
@url = %Q(# url = "http://www.foo.com/" # The base url that will be used to query the api.
  # Be sure to set a URL before the call to super.')
        end
        return @url
      end
    end
  end
end
