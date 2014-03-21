require 'logger'

module Elasticsearch
  module Logging
    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def self.logger=(logger)
      @logger = logger
    end
  end
end
