require 'bundler/setup'
Bundler.setup

require 'elasticsearch-rake-tasks.rb'

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter     = 'documentation'
end
