require "psych"
require "pry"
require "pry-debugger"

module Elasticsearch
  module Template
    class Handler < Psych::TreeBuilder

      attr_reader :reader

      def initialize(reader)
        @reader = reader
        super()
      end

      def document
        root.children.first
      end

      def last_node
        @last.children.last
      end

      def include_node?(node)
        node.respond_to?(:value) && node.value == 'inherit'
      end

      def scalar(value, anchor, tag, plain, quoted, style)
        if tag == "!file" && include_node?(last_node)
          @stack.pop
          @stack.last.children.pop

          nodes = @stack.last.children
          content = reader.parse_file(value).children.first
          nodes << content
          push content
        else
          super(value, anchor, tag, plain, quoted, style)
        end
      end
    end
  end
end
