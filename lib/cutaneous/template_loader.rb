
module Cutaneous
  class TemplateLoader
    attr_accessor :lexer_class

    def initialize(template_roots, format, extension = "cut")
      @roots, @format, @extension = template_roots, format, extension
    end

    def template(template)
      Template.new(lexer(template)).tap do |template|
        template.path   = path(template)
        template.loader = self
      end
    end

    def lexer(template)
      lexer_class.new(read(template))
    end


    def read(template_name)
      ::File.read(path(template_name))
    end

    def path(template_name)
      filename = [template_name, @format, @extension].join(".")
      @roots.map { |root| ::File.join(root, filename)}.detect { |path| ::File.exists?(path) }
    end
  end
end
