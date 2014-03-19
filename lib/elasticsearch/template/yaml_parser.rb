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
          pairs = find_include_nodes(node.children)
          STDOUT.puts "PAIRS: #{pairs.inspect}"

          inherit   = node.children.find{ |n| n.respond_to?(:value) && n.value == NODE_NAME }
          file_node = node.children.find{ |n| n.respond_to?(:tag) && n.tag == TAG_NAME }
          if inherit && file_node
            index = node.children.index(inherit)

            node.children.delete(inherit)
            node.children.delete(file_node)

            content = parse_file(file_node.value)
            content.children.each do |c|
              node.children.insert(index, c)
              index += 1
            end
          end
        end
      end

      private

      def find_include_nodes(nodes)
        includes = nodes.grep(Psych::Nodes::Scalar).select{ |n| n.value == NODE_NAME }
        includes.each_with_object([]) do |item, result|
          file = nodes.at(nodes.index(item) + 1)
          if file.send(:tag) == TAG_NAME
            result << [item, file]
          end
        end
      end
    end
  end
end
