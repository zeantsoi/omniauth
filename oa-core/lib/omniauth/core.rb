require 'rack'
require 'singleton'

module OmniAuth
  autoload :Builder,  'omniauth/builder'
  autoload :Strategy, 'omniauth/strategy'
  autoload :Test,     'omniauth/test'
  autoload :Form,     'omniauth/form'

  module Strategies
    autoload :Password, 'omniauth/strategies/password'
  end

  def self.strategies
    @@strategies ||= []
  end

  class Configuration
    include Singleton

    @@defaults = {
      :path_prefix => '/auth',
      :on_failure => Proc.new do |env, message_key|
        new_path = "#{OmniAuth.config.path_prefix}/failure?message=#{message_key}"
        [302, {'Location' => "#{new_path}", 'Content-Type'=> 'text/html'}, []]
      end,
      :form_css => Form::DEFAULT_CSS,
      :test_mode => false,
      :allowed_request_methods => [:get, :post],
      :mock_auth => {
        :default => {
          'uid' => '1234',
          'user_info' => {
            'name' => 'Bob Example',
            'email' => 'bob@example.com',
            'nickname' => 'bob'
          }
        }
      }
    }

    def self.defaults
      @@defaults
    end

    def initialize
      @@defaults.each_pair{|k,v| self.send("#{k}=",v)}
    end

    def on_failure(&block)
      if block_given?
        @on_failure = block
      else
        @on_failure
      end
    end

    attr_writer :on_failure
    attr_accessor :path_prefix, :allowed_request_methods, :form_css, :test_mode, :mock_auth, :full_host
  end
  
  def self.config
    Configuration.instance
  end

  def self.configure
    yield config
  end

  def self.mock_auth_for(provider)
    config.mock_auth[provider.to_sym] || config.mock_auth[:default]
  end

  module Utils
    CAMELIZE_SPECIAL = {
      'oauth' => 'OAuth',
      'oauth2' => 'OAuth2',
      'openid' => 'OpenID',
      'open_id' => 'OpenID',
      'github' => 'GitHub',
      'tripit' => 'TripIt',
      'soundcloud' => 'SoundCloud',
      'smugmug' => 'SmugMug',
      'cas' => 'CAS'
    }

    module_function

    def form_css
      "<style type='text/css'>#{OmniAuth.config.form_css}</style>"
    end

    def deep_merge(hash, other_hash)
      target = hash.dup

      other_hash.keys.each do |key|
        if other_hash[key].is_a? ::Hash and hash[key].is_a? ::Hash
          target[key] = deep_merge(target[key],other_hash[key])
          next
        end

        target[key] = other_hash[key]
      end

      target
    end

    def camelize(word, first_letter_in_uppercase = true)
      return CAMELIZE_SPECIAL[word.to_s] if CAMELIZE_SPECIAL[word.to_s]

      if first_letter_in_uppercase
        word.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      else
        word.first + camelize(word)[1..-1]
      end
    end
  end
end
