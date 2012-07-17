
module Cutaneous
  class TemplateLoader
    attr_accessor :lexer_class

    def initialize(template_roots, format, extension = "cut")
      @roots, @format, @extension = template_roots, format, extension
    end

    def template_file(template)
      template_path = path(template)
      raise UnknownTemplateError.new(@roots, template) if template_path.nil?

      Template.new(file_lexer(template_path)).tap do |template|
        template.path   = template_path
        template.loader = self
      end
    end

    alias_method :template, :template_file

    def template_string(template_string)
      Template.new(lexer(template_string)).tap do |template|
        template.loader = self
      end
    end

    def file_lexer(template_path)
      lexer(::File.read(template_path))
    end

    def lexer(template_string)
      lexer_class.new(template_string)
    end

    def path(template_name)
      filename = [template_name, @format, @extension].join(".")
      @roots.map { |root| ::File.join(root, filename)}.detect { |path| ::File.exists?(path) }
    end
  end
end
