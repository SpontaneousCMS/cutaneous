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
    result.must_equal "\nThis is right\n\nThis is right\n\nThis is right\n\n"
  end

  it "Will parse & execute a simple template with comments" do
    context = ContextHash(right: "right")
    result = engine.render("comments", "html", context)
    result.must_equal "\n"
  end

  it "Allows you to include other templates"
  it "Honors the format parameter"
end
