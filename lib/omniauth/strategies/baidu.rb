require "omniauth-oauth2"
require "json"
module OmniAuth
  module Strategies
    class Baidu < OmniAuth::Strategies::OAuth2
      option :client_options, {
        :site           => "http://openapi.baidu.com",
        :authorize_url  => "/oauth/2.0/authorize",
        :token_url      => "/oauth/2.0/token",
        :img_url        => "https://pcs.baidu.com/rest/2.0/pcs/thumbnail",
        :download_url   => "https://d.pcs.baidu.com/rest/2.0/pcs/file"
      }
      option :token_params, {
        :parse          => :json
      }

      uid do
        user_info['uid']
      end

      info do
        {
          :user_name      => user_info['uname'],
          :uid            => user_info['uid'],
          :is_app_user    => user_info['is_app_user'],
          :photo_info     => photo_info
        }
      end

      extra do
        {
          # :photo_info => photo_info
        }
      end

      def photo_info
        access_token.options[:mode] = :query
        access_token.options[:param_name] = 'access_token'
        @photo_info ||= JSON.parse access_token.get("https://pcs.baidu.com/rest/2.0/pcs/file", :params => {:path => "/apps/magic_photo", :method => "list"}).response.body
        for photo in @photo_info['list']
          photo['img_url'] = "#{options['client_options']['img_url']}?method=generate&access_token=#{access_token.token}&path=#{photo['path']}&height=200&width=200"
          photo['download_url'] = "#{options['client_options']['download_url']}?method=download&access_token=#{access_token.token}&path=#{photo['path']}"
        end
        p '----photo-----'
        p @photo_info
        p '---------'
        return @photo_info
      end

      def user_info
        access_token.options[:mode] = :query
        access_token.options[:param_name] = 'access_token'
        @user_info ||= JSON.parse access_token.get("https://openapi.baidu.com/rest/2.0/passport/users/getLoggedInUser").response.body
        is_app_user ||= JSON.parse access_token.get("https://openapi.baidu.com/rest/2.0/passport/users/isAppUser").response.body
        @user_info['is_app_user'] = is_app_user['result']
        p '-----user----'
        p @user_info
        p '---------'
        return @user_info
      end

      ##
      # You can pass +display+, +with_offical_account+ or +state+ params to the auth request, if
      # you need to set them dynamically. You can also set these options
      # in the OmniAuth config :authorize_params option.
      #
      # /auth/weibo?display=mobile&with_offical_account=1
      #
      def authorize_params
        super.tap do |params|
          %w[display with_offical_account state forcelogin].each do |v|
            if request.params[v]
              params[v.to_sym] = request.params[v]

              # to support omniauth-oauth2's auto csrf protection
              session['omniauth.state'] = params[:state] if v == 'state'
            end
          end
        end
      end
      
    end
  end
end

OmniAuth.config.add_camelization "baidu", "Baidu"
