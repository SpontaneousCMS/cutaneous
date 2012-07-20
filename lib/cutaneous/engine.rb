
module Cutaneous
  # Manages a set of Loaders that render templates
  class Engine
    attr_accessor :loader_class, :default_format

    def initialize(template_roots, lexer_class, default_format = "html")
      @roots          = Array(template_roots)
      @lexer_class    = lexer_class
      @loader_class   = FileLoader
      @default_format = default_format
    end

    def render_file(path, context, format = default_format)
      file_loader(format).render(path, context)
    end

    alias_method :render, :render_file

    def render_string(template_string, context, format = default_format)
      string_loader(format).render(template_string, context)
    end

    # Create and cache a file loader on a per-format basis
    def file_loader(format)
      file_loader_instance(format.to_s).tap do |loader|
        loader.lexer_class = @lexer_class
      end
    end

    # Not worth caching string templates as they are most likely to be one-off
    # instances & not repeated in the lifetime of the engine.
    def string_loader(format)
      StringLoader.new(file_loader(format))
    end

    def template_exists?(root, relative_path, format)
      file_loader(format).exists?(root, relative_path)
    end

    protected

    def file_loader_instance(format)
      loader_class.new(@roots, format)
    end
  end

  # A caching version of the default Engine implementation
  class CachingEngine < Engine
    def initialize(template_roots, lexer_class, default_format = "html")
      super
      @loader_class = CachedFileLoader
      @loaders      = {}
    end

    def file_loader_instance(format)
      @loaders[format] ||= super
    end
  end
end
