require File.expand_path('../test_helper', __FILE__)

describe Cutaneous do
  let(:template_root) { File.expand_path("../fixtures", __FILE__)                     }
  let(:engine)        { Cutaneous::Engine.new(template_root, Cutaneous::PublishLexer) }

  it "Will parse & execute a simple template with expressions" do
    context = ContextHash(right: "right", code: "<tag/>")
    result = engine.render("c", "html", context)
    result.must_equal ["aa\n", "bb", "cb", "ac", "ad", "ae", "cf", "ag\n"].join("\n\n")
  end
end

