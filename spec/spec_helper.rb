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

require "rubygems"
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
require File.expand_path(File.dirname(__FILE__) + "/../lib/rack_global_session")
require "spec"
require "flexmock"
require "tmpdir"
require "yaml"

Spec::Runner.configuration.mock_with :flexmock

module Rack::GlobalSessions
  # Helper class for managing OpenSSL keys.
  class KeyFactory
    # Make a new keystore, including a temporary directory.
    def initialize
      @keystore = Dir.mktmpdir
    end

    # Return the directory all keys are stored in.
    #
    # === Returns
    # keystore(String): directory where all keys are stored
    def dir
      @keystore
    end

    # Create a new OpenSSL key and write it to the temporary directory.
    #
    # === Parameters
    # name(String): name of key
    # write_private(Boolean): whether to write the private key to the directory
    #
    # === Returns
    # new_key(OpenSSL::PKey::RSA): key generated
    def create(name, write_private)
      new_key     = OpenSSL::PKey::RSA.generate(1024)
      new_public  = new_key.public_key.to_pem
      new_private = new_key.to_pem
      File.open(File.join(@keystore, "#{name}.pub"), 'w') { |f| f.puts new_public }
      File.open(File.join(@keystore, "#{name}.key"), 'w') { |f| f.puts new_key } if write_private
      new_key
    end

    # Remove all keys in the key store.
    def reset()
      Dir[File.join(@keystore, "*")].each { |f| FileUtils.remove_entry_secure f }
    end

    # Tear down the keystore.
    def destroy()
      FileUtils.remove_entry_secure(@keystore)
    end
  end

  module SpecHelpers
    shared_examples_for "Authentication" do
      before(:all) do
        @factory = KeyFactory.new
      end

      before(:each) do
        @first_key = @factory.create("first", true)
        @second_key = @factory.create("second", false)
        @config_hash = {
          "common" => {
            "attributes" => {
              "signed" => ["first", "second"],
              "insecure" => ["third"]
            },
            "authority" => "first",
            "trust" => "first",
            "timeout" => 10,
            "directory" => @factory.dir,
            "cookie" => {
              "name" => "aCookie",
              "domain" => "example.com",
            }
          }
        }
        @config_file = File.join(@factory.dir, "config")
        dump_config(@config_hash)
      end

      # Dump configuration for has_global_session to the config file.
      #
      # === Parameters
      # hash(Hash): has_global_session configuration
      def dump_config(hash)
        File.open(@config_file, "w") do |file|
          file << YAML.dump(hash)
        end
        @configuration = Configuration.new(@config_file, "test")
      end

      after(:all) do
        @factory.destroy
      end

      after(:each) do
        @factory.reset
      end
    end
  end
end
