
module Cutaneous
  # Manages a set of Loaders that render templates
  class Engine
    attr_reader   :roots
    attr_accessor :loader_class, :default_format

    def initialize(template_roots, syntax = Cutaneous::FirstPassSyntax, default_format = "html")
      @roots          = Array(template_roots)
      @syntax         = syntax
      @loader_class   = FileLoader
      @default_format = default_format
    end

    def render_file(path, context, format = default_format)
      file_loader(format).render(path, context)
    end

    alias_method :render, :render_file

    # need an explicit #render_string method so it's possible to distinguish
    # between a String which is a path to a template & a String which is a
    # template itself.
    def render_string(template_string, context, format = default_format)
      render_file(proc_template(template_string), context, format)
    end

    # Create and cache a file loader on a per-format basis
    def file_loader(format)
      file_loader_instance(format.to_sym).tap do |loader|
        loader.syntax = @syntax
      end
    end

    def template_exists?(relative_path, format)
      @roots.each do |root|
        return true if file_loader(format).exists?(root, relative_path)
      end
      false
    end

    def template_location(relative_path, format)
      @roots.each do |root|
        if (path = file_loader(format).location(root, relative_path))
          return path
        end
      end
      nil
    end

    def dynamic_template?(template_string)
      @syntax.is_dynamic?(template_string)
    end

    def convert(template, to_syntax, format = default_format)
      file_loader(format).convert(template, to_syntax)
    end

    def convert_string(template_string, to_syntax, format = default_format)
      convert(proc_template(template_string), to_syntax, format)
    end

    def proc_template(template_string)
      Proc.new { template_string }
    end

    protected

    def file_loader_instance(format)
      loader_class.new(@roots, format)
    end
  end

  # A caching version of the default Engine implementation
  class CachingEngine < Engine
    attr_writer :write_compiled_scripts

    def initialize(template_roots, syntax, default_format = "html")
      super
      @loader_class = CachedFileLoader
      @loaders      = {}
      @write_compiled_scripts = true
    end

    def file_loader_instance(format)
      @loaders[format] ||= super.tap do |loader|
        loader.write_compiled_scripts = @write_compiled_scripts if loader.respond_to?(:write_compiled_scripts=)
      end
    end
  end
end
