require File.expand_path('../helper', __FILE__)

require 'tmpdir'

describe Cutaneous do
  let(:source_template_root) { File.expand_path("../fixtures", __FILE__) }
  let(:dest_template_root) { Dir.mktmpdir }
  let(:engine)        {
    Cutaneous::Engine.new(dest_template_root, Cutaneous::PublishLexer).tap do |engine|
      engine.loader_class = Cutaneous::CachedFileLoader
    end
  }

  def template(source, format = "html")
    filename =  "#{source}.#{format}.cut"
    dest_path = File.join(dest_template_root, filename)
    FileUtils.mkdir_p(File.dirname(dest_path))
    FileUtils.cp(File.join(source_template_root, filename), dest_path)
    source
  end

  def remove_template(source, format = "html")
    filename =  "#{source}.#{format}.cut"
    dest_path = File.join(dest_template_root, filename)
    FileUtils.rm(dest_path)
  end

  it "Reads templates from the cache if they have been used before" do
    templates = %w(a b c)
    context = ContextHash(right: "right")

    templates.each do |t|
      template(t)
    end
    result1 = engine.render("c", "html", context)

    templates.each do |t|
      remove_template(t)
    end

    result2 = engine.render("c", "html", context)
    result2.must_equal result1
  end
end
