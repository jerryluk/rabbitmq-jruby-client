#! /usr/bin/env jruby
# require 'rubygems' 

spec = Gem::Specification.new do |s| 
  s.name = "rabbitmq-jruby-client" 
  s.version = "0.1.2" 
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jerry Luk"]
  s.email = %q{jerryluk@gmail.com}
  s.date = %q{2009-02-09}
  s.description = %q{A RabbitMQ client for JRuby}
  s.homepage = "http://www.linkedin.com/in/jerryluk" 
  s.summary = %q{A RabbitMQ client for JRuby}
  s.files = Dir["{lib,spec}/**/*"]
  s.require_paths = ["lib"]
  s.has_rdoc = false
  s.rubygems_version = %q{1.3.0}
end 
