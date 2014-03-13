require 'spec_helper'

describe Elasticsearch::Template::MappingsReader do
  let(:template){ 'simple' }

  describe "#initialize" do
    it "creates object with path" do
      expect{ Elasticsearch::Template::MappingsReader.new('') }.to_not raise_error
    end
  end

  describe "simple template" do
    let(:path){ "#{examples_root}/#{template}" }
    subject{ Elasticsearch::Template::MappingsReader.new(path).read }

    it "contains a type named 'foo'" do
      subject['foo'].should be_true
    end

    context "type 'foo'" do
      it "contains a property 'title'" do
        foo = subject['foo']
        foo['properties']['title'].should_not be_nil
      end
    end
  end
end
