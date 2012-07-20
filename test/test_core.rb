require File.expand_path('../helper', __FILE__)

describe Cutaneous do
  let(:template_root) { File.expand_path("../fixtures", __FILE__)                     }
  let(:engine)        { Cutaneous::Engine.new(template_root, Cutaneous::FirstPassLexer, "html") }

  it "Will parse & execute a simple template with expressions" do
    context = ContextHash(right: "right", code: "<tag/>")
    result = engine.render("expressions", context)
    result.must_equal "This is right &lt;tag/&gt;\n"
  end

  it "Will parse & execute a simple template with statements" do
    context = ContextHash(right: "right")
    result = engine.render("statements", context)
    result.must_equal "\nThis is right 0\n\nThis is right 1\n\nThis is right 2\n\n"
  end

  it "Will parse & execute a simple template with comments" do
    context = ContextHash(right: "right")
    result = engine.render("comments", context)
    result.must_equal "\n"
  end

  it "Will remove whitespace after tags with a closing '-'" do
    context = ContextHash(right: "right")
    result = engine.render("whitespace", context)
    expected = ["aa", "here 0", "here 1", "here 2\n", "ac\n", "ad\n", "ae\n", "af\n", "ag\n"].join("\n")
    result.must_equal expected
  end

  it "Allows you to include other templates and pass them parameters" do
    context = ContextHash(right: "right")
    result = engine.render("include", context)
    result.must_equal "right = right\nright = wrong\nright = left\n"
  end

  it "Honors the format parameter" do
    context = ContextHash(right: "right")
    result = engine.render("include", context, "rss")
    result.must_equal "right = rss\nwrong = rss\nleft = rss\n"
  end

  it "Passes instance variables onto includes" do
    context = ContextHash(right: "right")
    result = engine.render("instance", context)
    result.must_equal "left = wrong\n"
  end

  it "Allows you to render a template string" do
    context = ContextHash(right: "left")
    result = engine.render_string("${ right }", context)
    result.must_equal "left"
  end

  it "Lets you mix template tags" do
    context = ContextHash(right: "left")
    result = engine.render_string("${ right } = {{ result }}", context)
    result.must_equal "left = {{ result }}"
  end

  it "Has a configurable lexer class" do
    engine = Cutaneous::Engine.new(template_root, Cutaneous::SecondPassLexer)
    context = ContextHash(right: "wrong")
    result = engine.render_string("${ left } = {{ right }}", context)
    result.must_equal "${ left } = wrong"
  end

  it "Allows for multiple template roots" do
    roots = Array(template_root)
    roots.push File.join(template_root, "other")
    engine = Cutaneous::Engine.new(roots, Cutaneous::FirstPassLexer)
    context = ContextHash(right: "wrong")
    result = engine.render_string('%{ include "different" }', context)
    result.must_equal "wrong\n"
  end

  it "Throws a resonable error if asked to include a non-existant file" do
    context = ContextHash(right: "wrong")
    test = proc { engine.render_string('%{ include "different" }', context) }
    test.must_raise Cutaneous::UnknownTemplateError
  end

  it "Maintains source line numbers for exceptions" do
    context = ContextHash(right: "wrong")
    test = proc { engine.render("error", context) }
    test.must_raise RuntimeError
    backtrace = message = nil
    begin
      test.call
    rescue RuntimeError => e
      message   = e.message
      backtrace = e.backtrace
    end
    filename, line = backtrace.first.split(":")
    filename.must_equal File.join(template_root, "error.html.cut")
    line.must_equal message
  end

  it "Maintains source line numbers for exceptions raised by includes" do
    context = ContextHash(right: "wrong")
    test = proc { engine.render("included_error", context) }
    test.must_raise RuntimeError
    backtrace = message = nil
    begin
      test.call
    rescue RuntimeError => e
      message   = e.message
      backtrace = e.backtrace
    end
    filename, line = backtrace.first.split(":")
    filename.must_equal File.join(template_root, "other/error.html.cut")
    line.must_equal message
  end

  it "Renders proc instances as strings" do
    context = ContextHash(right: "wrong")
    template = proc { "right" }
    result = engine.render(template, context, "rss")
    result.must_equal "right"
  end

  it "Allows for configuration of the engine's default format" do
    engine.default_format = "rss"
    context = ContextHash(right: "right")
    result = engine.render("include", context)
    result.must_equal "right = rss\nwrong = rss\nleft = rss\n"
  end

  it "Accepts absolute template paths" do
    context = ContextHash(right: "right", code: "<tag/>")
    result = engine.render(File.join(template_root, "expressions"), context)
    result.must_equal "This is right &lt;tag/&gt;\n"
  end
end
