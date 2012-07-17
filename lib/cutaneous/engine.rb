
module Cutaneous
  class Engine
    def initialize(template_roots, lexer_class)
      @roots, @lexer_class = Array(template_roots), lexer_class
    end

    def loader(format)
      @loader ||= TemplateLoader.new(@roots, format).tap do |loader|
        loader.lexer_class = @lexer_class
      end
    end

    def render(path, format = "html", context)
      template(path, format).render(context)
    end

    def template(path, format = "html")
      loader = loader(format)
      loader.template(path)
    end
  end
end
