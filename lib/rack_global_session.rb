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
  module GlobalSessions
    Configuration = HasGlobalSession::Configuration
    Directory = HasGlobalSession::Directory
    Session = HasGlobalSession::GlobalSession
    class GlobalSession
      def initialize(app, file)
        @app = app
        Configuration.config_file = file
        Configuration.environment = ENV['RACK_ENV'] || 'development'
        @directory = Directory.new(Configuration['directory'])
        @cookie_name = Configuration['cookie']['name']
      end

      def read_cookie(env)
        begin
          if env['rack.cookies'].key?(@cookie_name)
            env['global_session'] = Session.new(@directory,
                                                env['rack.cookies'][@cookie_name])
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

      def renew_cookie(env)
        if Configuration['renew'] && env['global_session'] &&
            env['global_session'].directory.local_authority_name &&
            env['global_session'].expired_at < renew.to_i.minutes.from_now.utc
          env['global_session'].renew!
        end
      end

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
          # wipe cookie and proceed
          env['rack.cookies'][@cookie_name] = {:value => nil, :domain => domain, :expires => Time.at(0)}
          raise e
        end
      end

      def call(env)
        env['rack.cookies'] = {} unless env['rack.cookies']
        read_cookie(env)
        renew_cookie(env)
        begin
          @app.call(env)
        ensure
          update_cookie(env)
        end
      end
    end
  end
  GlobalSession = GlobalSessions::GlobalSession
end
