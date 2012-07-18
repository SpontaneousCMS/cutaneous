
module Cutaneous
  # Manages a set of Loaders that render templates
  class Engine
    attr_accessor :loader_class, :default_format

    def initialize(template_roots, lexer_class, default_format = "html")
      @roots          = Array(template_roots)
      @lexer_class    = lexer_class
      @loader_class   = FileLoader
      @default_format = default_format
      @loaders        = {}
    end

    def render(path_or_proc, context, format = default_format)
      case path_or_proc
      when String
        render_file(path_or_proc, context, format)
      when Proc
        render_string(path_or_proc.call, context, format)
      end
    end

    def render_file(path, context, format = default_format)
      template_file(path, format).render(context)
    end

    def render_string(template_string, context, format = default_format)
      template_string(template_string, format).render(context)
    end

    # Create and cache a file loader on a per-format basis
    def file_loader(format)
      @loaders[format.to_s] ||= loader_class.new(@roots, format).tap do |loader|
        loader.lexer_class = @lexer_class
      end
    end

    # Not worth caching string templates as they are most likely to be one-off
    # instances & not repeated in the lifetime of the engine.
    def string_loader(format)
      StringLoader.new(file_loader(format)).tap do |loader|
        loader.lexer_class = @lexer_class
      end
    end

    def template_file(path, format = default_format)
      loader = file_loader(format)
      loader.template(path)
    end

    def template_string(template_string, format = default_format)
      loader = string_loader(format)
      loader.template(template_string)
    end
  end

  class CachingEngine < Engine
    def initialize(template_roots, lexer_class, default_format = "html")
      super
      @loader_class = CachedFileLoader
    end
  end
end
