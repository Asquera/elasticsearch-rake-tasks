require "psych/inherit/file"

require "elasticsearch/logging"

require "elasticsearch/io/bulk_sink"
require "elasticsearch/io/chunked_sender"

require "elasticsearch/template/mappings_reader"
require "elasticsearch/template/compiler"

require "elasticsearch/rake/tasks/version"
require "elasticsearch/rake/tasks/seeder"
require "elasticsearch/rake/tasks/index_dump"

module Elasticsearch
  module Rake
    module Tasks
    end
  end
  module IO
  end
end
