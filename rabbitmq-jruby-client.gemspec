#! /usr/bin/env jruby
require 'rubygems' 

SPEC = Gem::Specification.new do |s| 
  s.name = "rabbitmq-jruby-client" 
  s.version = "0.1.0" 
  s.author = "Jerry Luk" 
  s.email = "jerryluk@gmail.com" 
  s.homepage = "http://www.linkedin.com/in/jerryluk" 
  s.platform = Gem::Platform::CURRENT 
  s.summary = "A RabbitMQ Client for JRuby" 
  s.files = Dir.glob("{docs,lib,spec}/**/*") 
  s.require_path = "lib"
end 
