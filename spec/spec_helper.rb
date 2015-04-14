require 'bundler/setup'
Bundler.setup

require 'elasticsearch-rake-tasks.rb'

RSpec.configure do |config|
  config.color = true
  config.formatter     = 'documentation'
end

def examples_root
  templates = "integration/examples/templates"
  @root ||= File.join(File.dirname(__FILE__), templates)
end
