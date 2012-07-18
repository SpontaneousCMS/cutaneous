
module Cutaneous
  # Manages a set of Loaders that render templates
  class Engine
    attr_accessor :loader_class

    def initialize(template_roots, lexer_class)
      @roots        = Array(template_roots)
      @lexer_class  = lexer_class
      @loader_class = FileLoader
      @loaders      = {}
    end

    def render_file(path, context, format = "html")
      template_file(path, format).render(context)
    end

    alias_method :render, :render_file

    def render_string(template_string, context, format = "html")
      template_string(template_string, format).render(context)
    end

    def file_loader(format)
      @loaders[format.to_s] ||= loader_class.new(@roots, format).tap do |loader|
        loader.lexer_class = @lexer_class
      end
    end

    def string_loader(format)
      StringLoader.new(file_loader(format)).tap do |loader|
        loader.lexer_class = @lexer_class
      end
    end

    def template_file(path, format = "html")
      loader = file_loader(format)
      loader.template(path)
    end

    def template_string(template_string, format = "html")
      loader = string_loader(format)
      loader.template(template_string)
    end
  end

  class CachingEngine < Engine
    def initialize(template_roots, lexer_class)
      super
      @loader_class = CachedFileLoader
    end
  end
end
