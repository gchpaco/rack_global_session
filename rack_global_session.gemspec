# -*-ruby-*-
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

require 'rubygems'

SPEC = Gem::Specification.new do |spec|
  spec.name = "rack_global_session"
  spec.version = "0.0.1"
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

  spec.add_dependency 'has_global_session', '~> 1.0'
  spec.add_dependency 'rack', '~> 1.2'
  spec.add_dependency 'rack-contrib', '~> 1.0.1'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'flexmock'

  candidates = Dir.glob("{lib,spec}/**/*") +
    ["LICENSE", "README.rdoc", "Rakefile", "rack_global_session.gemspec"]
  spec.files = candidates.sort
end
