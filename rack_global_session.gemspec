# -*-mode: ruby-mode; encoding: utf-8-*-
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

$:.push File.expand_path("../lib", __FILE__)
require "rack_global_session/version"

Gem::Specification.new do |spec|
  spec.name = "rack_global_session"
  spec.version = Rack::GlobalSessions::VERSION
  spec.summary = "Add global session handling to Rack servers"
  spec.description = <<EOS
A port of has_global_session to Rack middleware.
EOS
  spec.authors = ['Graham Hughes']
  spec.email = 'graham@rightscale.com'
  spec.platform = Gem::Platform::RUBY
  spec.has_rdoc = true
  spec.rdoc_options = ["--main", "README.rdoc", "--title", "Rack::GlobalSession"]
  spec.extra_rdoc_files = ["README.rdoc"]
  spec.required_ruby_version = '>= 1.8.7'
  spec.require_path = 'lib'

  spec.add_dependency 'activesupport', '~> 3.0.3'
  spec.add_dependency 'i18n', "~> 0.5.0"
  spec.add_dependency 'tzinfo'
  spec.add_dependency 'has_global_session', '~> 1.1.3'
  spec.add_dependency 'rack', '~> 1.2'
  spec.add_dependency 'rack-contrib', '~> 1.0.1'

  spec.add_development_dependency 'rspec', "~> 1.3"
  spec.add_development_dependency 'flexmock', "~> 0.8.11"
  spec.add_development_dependency 'rtags', "~> 0.97"

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
