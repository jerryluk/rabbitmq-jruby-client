#! /usr/bin/env jruby

spec = Gem::Specification.new do |s| 
  s.name = 'rabbitmq-jruby-client' 
  s.version = '0.1.2' 
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ['Jerry Luk']
  s.email = 'jerryluk@gmail.com'
  s.date = '2009-02-09'
  s.summary = 'A RabbitMQ client for JRuby'
  s.description = s.summary
  s.homepage = 'http://www.linkedin.com/in/jerryluk'
  s.require_path = 'lib'
  s.files = Dir["{lib}/**/*"]
  s.has_rdoc = false
  s.rubygems_version = '1.3.0'
end 
