require 'spec_helper'

describe Elasticsearch::IO::ChunkedSender do
  describe "#send" do
    let(:lines){ [
        "{'index':{'_type':'clip','_id':'1234'}}",
        "{'foo':'bar', 'test': '123'}"
      ].join("\n")
    }

    let(:sink){ double('sink', :<< => lines, :flush => true) }
    subject{ Elasticsearch::IO::ChunkedSender.new(sink) }

    it "should call <<" do
      sink.should_receive(:<<).once
      subject.send(lines)
    end

    it "should call flush" do
      sink.should_receive(:flush).once
      subject.send(lines)
    end
  end
end
