
module Cutaneous
  class Engine
    def initialize(template_roots, lexer_class)
      @roots, @lexer_class = Array(template_roots), lexer_class
    end

    def loader(format)
      @loader ||= Loader.new(@roots, format).tap do |loader|
        loader.lexer_class = @lexer_class
      end
    end

    def render_file(path, format, context)
      template_file(path, format).render(context)
    end

    alias_method :render, :render_file

    def render_string(template_string, format, context)
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
end
