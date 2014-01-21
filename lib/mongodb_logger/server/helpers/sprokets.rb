require 'base64'
require 'rack/utils'
require 'sprockets'

module MongodbLogger

  module AssetHelpers
    def asset_path(source)
      "#{request.env['SCRIPT_NAME']}/assets/#{Assets.instance.find_asset(source).digest_path}" unless Assets.instance.find_asset(source).nil?
    end
    def asset_data_uri(source)
      unless Assets.instance.find_asset(source).nil?
        asset  = Assets.instance.find_asset(source)
        base64 = Base64.encode64(asset.to_s).gsub(/\s+/, "")
        "data:#{asset.content_type};base64,#{Rack::Utils.escape(base64)}"
      end
    end
  end

  class Assets < Sprockets::Environment
    class << self
      def instance(root = nil)
        assets_path = File.expand_path('../../../../../app/assets', __FILE__)
        @instance ||= new(assets_path)
      end
    end

    def initialize(assets_path)
      super
      append_path(File.join(assets_path, 'stylesheets'))
      append_path(File.join(assets_path, 'javascripts'))
      append_path(File.join(assets_path, 'images'))

      context_class.instance_eval do
        include AssetHelpers
      end
    end
  end

end