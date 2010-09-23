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

require File.expand_path(File.dirname(__FILE__) + "/spec_helper")
require 'tmpdir'
require 'fileutils'

module Rack
  describe GlobalSession do
    it_should_behave_like 'Authentication'

    before(:each) do
      ENV['SERVER_NAME'] = "server"
      ENV['RACK_ENV'] = "test"
    end

    it 'should create an empty session if none exists' do
      @app = Proc.new do |env|
        env['global_session'].should_not be_nil
        env['global_session'].should be_valid
      end
      environment = {}
      Rack::GlobalSession.new(@app, @config_file).call(environment)
      environment['rack.cookies']["aCookie"][:value].should_not be_nil
      environment['rack.cookies']["aCookie"][:domain].should == "example.com"
      environment['rack.cookies']["aCookie"][:expires].should <= 10.minutes.from_now.utc
      environment['rack.cookies']["aCookie"][:expires].should >= 9.minutes.from_now.utc
    end
    it 'should use SERVER_NAME if no domain is specified' do
      @config_hash["common"]["cookie"].delete("domain")
      dump_config(@config_hash)
      environment = {}
      Rack::GlobalSession.new(lambda {}, @config_file).call(environment)
      environment['rack.cookies']["aCookie"][:domain].should == "server"
    end

    it 'should raise an error on ludicrously invalid cookies' do
      environment = {"rack.cookies" => {
          "aCookie" => "foo"
        }}
      lambda {
        Rack::GlobalSession.new(lambda {}, @config_file).call(environment)
      }.should raise_error(HasGlobalSession::MalformedCookie, /buffer error/)
    end

    it 'should raise an error on well formed but invalid cookies' do
      hash = {'id' => "root",
        'tc' => Time.now, 'te' => Time.now,
        'ds' => "not actually a signature",
        'dx' => {"third" => 4},
        's' => @first_key.private_encrypt("blah"),
        'a' => "first",
      }
      json = HasGlobalSession::Encoding::JSON.dump(hash)
      compressed = Zlib::Deflate.deflate(json, Zlib::BEST_COMPRESSION)
      base64 = HasGlobalSession::Encoding::Base64Cookie.dump(compressed)
      environment = {"rack.cookies" => {"aCookie" => base64}}
      lambda {
        Rack::GlobalSession.new(lambda {}, @config_file).call(environment)
      }.should raise_error(OpenSSL::PKey::RSAError)
    end

    context 'with a valid environment' do
      before(:each) do
        @environment = {}
        Rack::GlobalSession.new(lambda {}, @config_file).call(@environment)
        @environment['rack.cookies']['aCookie'] = @environment['rack.cookies']['aCookie'][:value]
      end

      it 'should read a valid cookie' do
        Rack::GlobalSession.new(lambda {}, @config_file).call(@environment)
      end

      context 'with an expired session' do
        before(:each) do
          Rack::GlobalSession.new(lambda {|e|
                                    e['global_session'].instance_variable_set(:@expired_at,
                                                                              1.minutes.from_now)},
                                  @config_file).call(@environment)
          @environment['rack.cookies']['aCookie'] = @environment['rack.cookies']['aCookie'][:value]
        end

        it 'should renew expired cookies when permitted' do
          Rack::GlobalSession.new(lambda {|e| e['global_session'].renew!},
                                  @config_file).call(@environment)
          @environment['rack.cookies']["aCookie"][:expires].should <= 10.minutes.from_now.utc
          @environment['rack.cookies']["aCookie"][:expires].should >= 9.minutes.from_now.utc
        end

        it 'should renew expired cookies implicitly' do
          Rack::GlobalSession.new(lambda {|e| e['global_session'].expired_at.should >=
                                    9.minutes.from_now.utc},
                                  @config_file).call(@environment)
        end
      end

      context 'when it is not an authority' do
        before(:each) do
          @config_hash["common"].delete("authority")
          dump_config(@config_hash)
        end

        it 'should not renew expired cookies' do
          lambda {
            Rack::GlobalSession.new(lambda {|e| e['global_session'].renew!},
                                    @config_file).call(@environment)
          }.should raise_error(HasGlobalSession::NoAuthority)
        end

        it 'should not attempt to update the cookie when it is not an authority' do
          lambda {
            Rack::GlobalSession.new(lambda {|e| e['global_session']['first'] = 4},
                                    @config_file).call(@environment)
          }.should raise_error(HasGlobalSession::NoAuthority)
        end
      end

      it 'should update cookies correctly' do
        Rack::GlobalSession.new(lambda { |env|
                                  env['global_session']['first'] = "foo"
                                  env['global_session']['second'] = "bar"
                                }, @config_file).call(@environment)
        oldvalue = @environment['rack.cookies']['aCookie'][:value]
        @environment['rack.cookies']['aCookie'] = @environment['rack.cookies']['aCookie'][:value]
        Rack::GlobalSession.new(lambda { |env|
                                  env['global_session']['first'].should == "foo"
                                  env['global_session']['second'].should == "bar"
                                  env['global_session']['first'] = "baz"
                                }, @config_file).call(@environment)
        @environment['rack.cookies']['aCookie'][:value].should_not == oldvalue
      end

      it 'should unconditionally wipe the cookie if an error occurs' do
        @environment['rack.cookies']['aCookie'].should_not be_nil
        lambda {
          Rack::GlobalSession.new(lambda {raise "foo"}, @config_file).call(@environment)
        }.should raise_error
        @environment['rack.cookies']['aCookie'][:value].should be_nil
      end

      it 'should refuse cookies from invalid certification authorities' do
        @config_hash["common"]["trust"] = "second"
        dump_config(@config_hash)
        lambda {
          Rack::GlobalSession.new(lambda {}, @config_file).call(@environment)
        }.should raise_error(SecurityError)
    end
    end
  end
end
