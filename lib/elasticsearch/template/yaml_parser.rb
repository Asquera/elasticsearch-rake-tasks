require 'ostruct'

module Elasticsearch
  module Yaml
    class Parser
      NODE_NAME = 'inherit'
      TAG_NAME  = '!file'

      def load_file(file)
        parse_file(file).to_ruby
      end

      def parse_file(file)
        document = parse_yaml_content(File.read(file))
        replace_inherit_node(document)
        document
      rescue StandardError => e
        # STDOUT.puts "Error while reading file #{file}: #{e}"
        raise e
      end

      def parse_yaml_content(content)
        YAML.parse(content).root
      end

      def replace_inherit_node(document)
        document.grep(Psych::Nodes::Mapping).each do |node|
          nodes = node.children
          find_include_nodes(nodes).reverse.each do |pair|
            index = nodes.index(pair.item)

            nodes.delete_if{ |n| n == pair.item || n == pair.file }

            content = parse_file(pair.file.value)
            content.children.each do |c|
              nodes.insert(index, c)
              index += 1
            end
          end
        end
      end

      private

      def insertion_node?(n, next_node)
        n.class == Psych::Nodes::Scalar &&
        n.value == NODE_NAME &&
        next_node &&
        next_node.respond_to?(:tag) &&
        next_node.tag == TAG_NAME
      end

      def find_include_nodes(nodes)
        nodes.map do |n|
          next_node = nodes.at(nodes.index(n) + 1)
          if insertion_node?(n, next_node)
            [n, next_node]
          end
        end.compact.map { |x| OpenStruct.new(item: x[0], file: x[1]) }
      end
    end
  end
end
