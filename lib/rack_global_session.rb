#--
# Copyright: Copyright (c) 2010 RightScale, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require "has_global_session"
require "active_support/time"

module Rack
  # A port of has_global_session to Rack middleware.
  module GlobalSessions
    # Alias some of the HasGlobalSession classes for easy typing.
    Configuration = HasGlobalSession::Configuration
    Directory = HasGlobalSession::Directory
    Session = HasGlobalSession::GlobalSession
    # Global session middleware.  Note: this class relies on
    # Rack::Cookies being used higher up in the chain.
    class GlobalSession
      # Make a new global session.
      #
      # The optional block here controls an alternate ticket retrieval
      # method.  If no ticket is stored in the cookie jar, this
      # function is called.  If it returns a non-nil value, that value
      # is the ticket.
      #
      # === Parameters
      # app(Rack client): application to run
      # file(String): filename for has_global_session configuration
      # block: optional alternate ticket retrieval function
      def initialize(app, file, &block)
        @app = app
        Configuration.config_file = file
        Configuration.environment = ENV['RACK_ENV'] || 'development'
        @cookie_retrieval = block
        @directory = Directory.new(Configuration['directory'])
        @cookie_name = Configuration['cookie']['name']
      end

      # Read a cookie from the Rack environment.
      #
      # === Parameters
      # env(Hash): Rack environment.
      def read_cookie(env)
        begin
          if env['rack.cookies'].key?(@cookie_name)
            env['global_session'] = Session.new(@directory,
                                                env['rack.cookies'][@cookie_name])
          elsif @cookie_retrieval && cookie = @cookie_retrieval.call(env)
            env['global_session'] = Session.new(@directory, cookie)
          else
            env['global_session'] = Session.new(@directory)
          end
          true
        rescue Exception => e
          # Reinitialize global session cookie
          env['global_session'] = Session.new(@directory)
          update_cookie(env)
          raise e
        end
      end

      # Renew the session ticket.
      #
      # === Parameters
      # env(Hash): Rack environment
      def renew_ticket(env)
        if Configuration['renew'] && env['global_session'] &&
            env['global_session'].directory.local_authority_name &&
            env['global_session'].expired_at < renew.to_i.minutes.from_now.utc
          env['global_session'].renew!
        end
      end

      # Update the cookie jar with the revised ticket.
      #
      # === Parameters
      # env(Hash): Rack environment
      def update_cookie(env)
        domain = Configuration['cookie']['domain'] || ENV['SERVER_NAME']
        begin
          if env['global_session'] && env['global_session'].valid?
            value = env['global_session'].to_s
            expires = Configuration['ephemeral'] ? nil : env['global_session'].expired_at
            unless env['rack.cookies'].key?(@cookie_name) &&
                env['rack.cookies'][@cookie_name] == value
              env['rack.cookies'][@cookie_name] = {:value => value, :domain => domain, :expires => expires}
            end
          else
            # write an empty cookie
            env['rack.cookies'][@cookie_name] = {:value => nil, :domain => domain, :expires => Time.at(0)}
          end
        rescue Exception => e
          wipe_cookie(env)
          raise e
        end
      end

      # Delete the ticket from the cookie jar.
      #
      # === Parameters
      # env(Hash): Rack environment
      def wipe_cookie(env)
        domain = Configuration['cookie']['domain'] || ENV['SERVER_NAME']
        env['rack.cookies'][@cookie_name] = {:value => nil, :domain => domain, :expires => Time.at(0)}
      end

      # Rack request chain.  Sets up the global session ticket from
      # the environment and passes it up the chain.
      def call(env)
        env['rack.cookies'] = {} unless env['rack.cookies']
        read_cookie(env)
        renew_ticket(env)
        begin
          @app.call(env)
        rescue Exception => e
          wipe_cookie(env)
          raise e
        else
          update_cookie(env)
        end
      end
    end
  end
  GlobalSession = GlobalSessions::GlobalSession
end
