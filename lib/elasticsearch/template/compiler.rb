require 'yaml'

module Elasticsearch
  module Template
    class Compiler
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def compile(template)
        unless File.directory?("#{path}/#{template}")
          raise "Template #{template} not a directory"
        end
        mappings = read_mappings(template)
        mappings
      end

      def read_mappings(template)
        mappings_path = "#{path}/#{template}/mappings"
        MappingsReader.new(mappings_path).read
      rescue
        {}
      end
    end
  end
end
