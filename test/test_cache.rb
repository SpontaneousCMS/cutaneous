require File.expand_path('../helper', __FILE__)

require 'tmpdir'

describe Cutaneous do
  let(:source_template_root) { File.expand_path("../fixtures", __FILE__) }
  let(:dest_template_root)   { Dir.mktmpdir }
  let(:engine)               { cached_engine }

  def cached_engine
    Cutaneous::CachingEngine.new(dest_template_root, Cutaneous::FirstPassLexer, "html")
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

  def template_path(source, format = "html")
    filename =  "#{source}.#{format}.cut"
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
    context = ContextHash(right: "right")
    templates.each do |t|
      template(t)
    end
    result1 = engine.render("c", context)

    # Ensure that the cached script file is being used by overwriting its contents
    path = template_path("c")
    assert ::File.exists?(path), "Template cache should have created '#{path}'"
    path = template_path("c").gsub(/\.cut$/, ".rb")
    File.open(path, "w") do |f|
      f.write("__buf << 'right'")
    end

    engine = cached_engine
    result2 = engine.render("c", context)
    result2.must_equal "right"
  end
end
