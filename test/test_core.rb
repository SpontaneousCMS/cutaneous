require File.expand_path('../helper', __FILE__)

describe "Parsers" do
  let(:template_root) { File.expand_path("../fixtures", __FILE__)                     }
  def read_template(template)
    File.read(File.join(template_root, template))
  end

  describe "First pass parser" do

    subject { Cutaneous::Engine.new(template_root, Cutaneous::FirstPassSyntax, "html") }

    it "will parse & execute a simple template with expressions" do
      context = ContextHash(right: "right", code: "<tag/>")
      result = subject.render("expressions1", context)
      result.must_equal "This is right &lt;tag/&gt;\n"
    end

    it "will parse & execute a simple template with statements" do
      context = ContextHash(right: "right")
      result = subject.render("statements1", context)
      result.must_equal "\nThis is right 0\n\nThis is right 1\n\nThis is right 2\n\n"
    end

    it "will parse & execute a simple template with comments" do
      context = ContextHash(right: "right")
      result = subject.render("comments1", context)
      result.must_equal "\n"
    end

    it "will remove whitespace after tags with a closing '-'" do
      context = ContextHash(right: "right")
      result = subject.render("whitespace1", context)
      expected = ["aa", "here 0", "here 1", "here 2\n", "ac\n", "ad\n", "ae\n", "af\n", "ag\n"].join("\n")
      result.must_equal expected
    end

    it "can convert a template to another syntax" do
      result = subject.convert('statements1', Cutaneous::SecondPassSyntax)
      result.must_equal read_template('statements2.html.cut')
    end

    it "can convert a template string to another syntax" do
      result = subject.convert_string(read_template('statements1.html.cut'), Cutaneous::SecondPassSyntax)
      result.must_equal read_template('statements2.html.cut')
    end

    it "can convert a template proc to another syntax" do
      result = subject.convert(proc { read_template('statements1.html.cut') }, Cutaneous::SecondPassSyntax)
      result.must_equal read_template('statements2.html.cut')
    end
  end

  describe "Second pass parser" do
    let(:template_root) { File.expand_path("../fixtures", __FILE__)                     }
    subject { Cutaneous::Engine.new(template_root, Cutaneous::SecondPassSyntax, "html") }

    it "will parse & execute a simple template with expressions" do
      context = ContextHash(right: "right", code: "<tag/>")
      result = subject.render("expressions2", context)
      result.must_equal "This is right &lt;tag/&gt; <tag/>\n"
    end

    it "will parse & execute a simple template with statements" do
      context = ContextHash(right: "right")
      result = subject.render("statements2", context)
      result.must_equal "\nThis is right 0\n\nThis is right 1\n\nThis is right 2\n\n"
    end

    it "will parse & execute a simple template with comments" do
      context = ContextHash(right: "right")
      result = subject.render("comments2", context)
      result.must_equal "\n"
    end

    it "will remove whitespace after tags with a closing '-'" do
      context = ContextHash(right: "right")
      result = subject.render("whitespace2", context)
      expected = ["here 0", "here 1", "here 2\n"].join("\n")
      result.must_equal expected
    end

    it "can convert a template to another syntax" do
      result = subject.convert('statements2', Cutaneous::FirstPassSyntax)
      result.must_equal read_template('statements1.html.cut')
    end

    it "can convert a template string to another syntax" do
      result = subject.convert_string(read_template('statements2.html.cut'), Cutaneous::FirstPassSyntax)
      result.must_equal read_template('statements1.html.cut')
    end

    it "can convert a template proc to another syntax" do
      result = subject.convert(proc { read_template('statements2.html.cut') }, Cutaneous::FirstPassSyntax)
      result.must_equal read_template('statements1.html.cut')
    end
  end
end

describe Cutaneous do
  let(:template_root) { File.expand_path("../fixtures", __FILE__)                     }
  let(:engine)        { engine1 }
  let(:engine1)        { Cutaneous::Engine.new(template_root, Cutaneous::FirstPassSyntax, "html") }
  let(:engine2)        { Cutaneous::Engine.new(template_root, Cutaneous::SecondPassSyntax, "html") }

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
    engine = Cutaneous::Engine.new(template_root, Cutaneous::SecondPassSyntax)
    context = ContextHash(right: "wrong")
    result = engine.render_string("${ left } = {{ right }}", context)
    result.must_equal "${ left } = wrong"
  end

  it "Allows for multiple template roots" do
    roots = Array(template_root)
    roots.push File.join(template_root, "other")
    engine = Cutaneous::Engine.new(roots, Cutaneous::FirstPassSyntax)
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
    result = engine.render(File.join(template_root, "expressions1"), context)
    result.must_equal "This is right &lt;tag/&gt;\n"
  end

  it "Tests for the existence of a template file for a certain format" do
    assert engine.template_exists?(template_root, "expressions1", "html")
    assert engine.template_exists?(template_root, "other/error", "html")
    assert engine.template_exists?(template_root, "include", "rss")
    refute engine.template_exists?(template_root, "missing", "rss")
  end

  it "Passes any instance variables & locals between contexts" do
    context = ContextHash(right: "left")
    result1 = engine.render("instance", context)
    context = ContextHash(context)
    result2 = engine.render("instance", context)
    result2.must_equal result1
  end

  it "Silently discards missing variables" do
    context = ContextHash(right: "left")
    result1 = engine.render("missing", context)
    result1.must_equal "missing: \n"
  end

  it "Overwrites object methods with parameters" do
    klass = Class.new(Object) do
      def monkey; "see"; end
      def to_s  ; "object"; end
    end
    context = TestContext.new(klass.new)
    result = engine.render_string("${ monkey } ${ to_s }", context)
    result.must_equal "see object"
    context = TestContext.new(klass.new, monkey: "magic", to_s: "fairy")
    result = engine.render_string("${ monkey } ${ to_s }", context)
    result.must_equal "magic fairy"
  end

  it "Overwrites helper methods with local values" do
    context_class = Class.new(TestContext) do
      def monkey
        "wrong"
      end
    end
    context = context_class.new(Object.new, monkey: "magic", to_s: "fairy")
    # def context.monkey; "wrong"; end
    result = engine.render_string("${ monkey } ${ to_s }", context)
    result.must_equal "magic fairy"
  end

  it "Preserves the original context locals after includes" do
    context = ContextHash({})
    result = engine.render("locals/parent", context)
    result.must_equal "Child 1\nChild 2\n\n"
  end
end
