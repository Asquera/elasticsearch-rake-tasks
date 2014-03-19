module Elasticsearch
  module Yaml
    class Parser
      def parse_yaml_file(file)
        document = parse_yaml_content(File.read(file))
        replace_inherit_node(document)
        document
      rescue StandardError => e
        STDOUT.puts "Error while reading file #{file}: #{e}"
        raise e
      end

      def parse_yaml_content(content)
        YAML.parse(content).root
      end

      def replace_inherit_node(document)
        document.grep(Psych::Nodes::Mapping).each do |node|
          inherit   = node.children.find{ |n| n.respond_to?(:value) && n.value == 'inherit' }
          file_node = node.children.find{ |n| n.respond_to?(:tag) && n.tag == '!file' }
          if inherit && file_node
            index = node.children.index(inherit)

            node.children.delete(inherit)
            node.children.delete(file_node)

            content = parse_yaml_file(file_node.value)
            content.children.each do |c|
              node.children.insert(index, c)
              index += 1
            end
          end
        end
      end
    end
  end
end
