require File.expand_path('../helper', __FILE__)

require 'tmpdir'

describe Cutaneous do
  let(:source_template_root) { File.expand_path("../fixtures", __FILE__) }
  let(:dest_template_root)   { Dir.mktmpdir }
  let(:engine)               { cached_engine }

  def cached_engine
    Cutaneous::CachingEngine.new(dest_template_root, Cutaneous::FirstPassSyntax, "html")
  end

  def template(source, format = "html")
    dest_path = template_path(source, format)
    FileUtils.mkdir_p(File.dirname(dest_path))
    FileUtils.cp(File.join(source_template_root, File.basename(dest_path)), dest_path)
    source
  end

  def remove_template(source, format = "html")
    FileUtils.rm(template_path(source, format))
  end

  def template_path(source, format = "html", extension = "cut")
    filename =  "#{source}.#{format}.#{extension}"
    File.join(dest_template_root, filename)
  end

  it "Reads templates from the cache if they have been used before" do
    templates = %w(a b c)
    context = ContextHash(right: "right")

    templates.each do |t|
      template(t)
    end
    result1 = engine.render("c", context)

    templates.each do |t|
      remove_template(t)
    end

    result2 = engine.render("c", context)
    result2.must_equal result1
  end

  it "Saves the ruby script as a .rb file and uses it if present" do
    templates = %w(a b c)
    templates.each do |t|
      template(t)
    end

    context = ContextHash(right: "right")
    result1 = engine.render("c", context)

    # Ensure that the cached script file is being used by overwriting its contents
    path = template_path("c", "html", "rb")
    assert ::File.exists?(path), "Template cache should have created '#{path}'"
    File.open(path, "w") do |f|
      f.write("__buf << 'right'")
    end

    engine = cached_engine
    result2 = engine.render("c", context)
    result2.must_equal "right"
  end

  it "Recompiles the cached script if the template is newer" do
    templates = %w(a b c)
    templates.each do |t|
      template(t)
    end
    context = ContextHash(right: "right")

    result1 = engine.render("c", context)

    now = Time.now

    template_path = template_path("c", "html")
    script_path   = template_path("c", "html", "rb")
    assert ::File.exists?(script_path), "Template cache should have created '#{script_path}'"

    File.open(template_path, "w") { |f| f.write("template") }
    File.utime(now, now, template_path)
    File.utime(now - 100, now - 100, script_path)

    engine = cached_engine
    result1 = engine.render("c", context)
    result1.must_equal "template"
  end

  it "Doesn't write a compiled script file if configured not to do so" do
    engine.write_compiled_scripts = false
    templates = %w(a b c)
    templates.each do |t|
      template(t)
    end
    context = ContextHash(right: "right")

    result1 = engine.render("c", context)
    script_path   = template_path("c", "html", "rb")
    refute ::File.exists?(script_path), "Template cache should not have created '#{script_path}'"
  end

  it "doesn't attempt to write a cached script for Proc templates" do
    context = ContextHash(right: "right")
    result1 = engine.render(Proc.new { "This is ${right}"}, context)
  end
end
