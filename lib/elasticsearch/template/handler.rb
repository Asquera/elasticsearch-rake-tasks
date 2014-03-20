require "psych"

module Elasticsearch
  module Template
    class Handler < Psych::TreeBuilder
      TAG_NAME = '!file'
      NODE_NAME = 'inherit'

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
        node.respond_to?(:value) && node.value == NODE_NAME
      end

      def scalar(value, anchor, tag, plain, quoted, style)
        if tag == TAG_NAME && include_node?(last_node)
          pop_previous_node

          nodes = @stack.last.children
          content = reader.parse_file(value).children.first
          nodes << content
          push content
        else
          super
        end
      end

      private

      def pop_previous_node
        @stack.pop
        @stack.last.children.pop
      end
    end
  end
end
