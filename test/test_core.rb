require File.expand_path('../helper', __FILE__)

describe Cutaneous do
  let(:template_root) { File.expand_path("../fixtures", __FILE__)                     }
  let(:engine)        { Cutaneous::Engine.new(template_root, Cutaneous::PublishLexer) }

  it "Will parse & execute a simple template with expressions" do
    context = ContextHash(right: "right", code: "<tag/>")
    result = engine.render("expressions", "html", context)
    result.must_equal "This is right &lt;tag/&gt;\n"
  end

  it "Will parse & execute a simple template with statements" do
    context = ContextHash(right: "right")
    result = engine.render("statements", "html", context)
    result.must_equal "\nThis is right 0\n\nThis is right 1\n\nThis is right 2\n\n"
  end

  it "Will parse & execute a simple template with comments" do
    context = ContextHash(right: "right")
    result = engine.render("comments", "html", context)
    result.must_equal "\n"
  end

  it "Will remove whitespace after tags with a closing '-'" do
    context = ContextHash(right: "right")
    result = engine.render("whitespace", "html", context)
    expected = ["aa", "here 0", "here 1", "here 2\n", "ac\n", "ad\n", "ae\n", "af\n", "ag\n"].join("\n")
    result.must_equal expected
  end

  it "Allows you to include other templates"
  it "Honors the format parameter"
end
