require File.expand_path('../helper', __FILE__)

describe Cutaneous do
  let(:template_root) { File.expand_path("../fixtures", __FILE__)                     }
  let(:engine)        { Cutaneous::Engine.new(template_root, Cutaneous::PublishLexer) }

  it "Will parse & execute a simple template with expressions" do
    context = ContextHash(right: "right", code: "<tag/>")
    result = engine.render("c", "html", context)
    expected = ["aa\n\n", "ab", "bb", "cb", "ac", "ad", "ae", "cf", "ag\n"].join("\n\n")
    result.must_equal expected
  end

  it "Won't run code in inherited templates unless called" do
    context = ContextHash(right: "right", code: "<tag/>")
    result = engine.render("e", "html", context)
    result.must_equal ["da", "db", "dc", "ed\n\n"].join("\n\n")
  end
end

