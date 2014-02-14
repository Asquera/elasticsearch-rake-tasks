# Elasticsearch::Rake::Tasks

a collection of useful tasks to support a lean elasticsearch development workflow

## Installation

Add this line to your application's Gemfile:

    gem 'elasticsearch-rake-tasks'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install elasticsearch-rake-tasks

## Prerequisites

In order to get the elasticsearch rake tasks to find all templates and settings for an index, the following folder structure must be in place.

```
./resources
|-- elasticsearch
  |-- templates
    |-- application
      |-- mappings
        |-- _default.yaml
        |-- type_a.yaml
        |-- ..
      |-- settings.yaml
      |-- template_pattern
```

The `elasticsearch` folder must be located under a `resources` folder in the root directory of your project. Inside the `templates` folder a list of directories define the indices for which mappings and settings are used from, in the example above an index `application` would the available.

The following folders & files are used:

* `settings.yaml` defines the analyzers and filters that are made available for use in the type mappings
* `template_pattern` is used for versioning and defines the current active index, e.g. `application-1.0`. It is useful in the re-indexing step to define what the new index should be
* `mappings` is the folder where all type definitions reside. The files names must match exactly the document types that are indexed, e.g. when a document is of type Tweet, a `Tweet.yaml` (case sensitive) must be available in this folder describing the properties of such a document
* `_default.yaml` is typically the base type definition from which all types inherit shared definitions

## Usage

To show all available rake tasks, type `bundle exec rake -T` from root. When the elasticsearch folder structure is in place all settings for specified indices are automatically found and shown.

```
rake es:application:compile
```

Compiles the template for index `application`, while

```
rake es:application:reset
```

deletes the given template and recreates it.

```
rake es:dump[server,index]
```

Dumps the content of the ES index from given server to a file located under `./resources/elasticsearch/dumps`. To fill an elasticsearch index with data from a seed file use

```
rake es:seed[server,index]
```

this will seed the content of the file into the index.
The last rake task is used to dump the content from index into another.

```
rake es:reindex[server,index,index_to]
```

and should be used whenever the mappings or settings changed.

**Note** if no arguments are provided to the rake tasks `es:dump`, `es:seed` or `es:reindex` then the environment variables `ES_SERVER` and `ES_INDEX` need to be set.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
