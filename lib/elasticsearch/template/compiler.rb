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
      end
    end
  end
end
