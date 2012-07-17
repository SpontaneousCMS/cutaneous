module Cutaneous
  # Converts a template path into a Template instance
  class FileLoader
    attr_accessor :lexer_class

    def initialize(template_roots, format, extension = "cut")
      @roots, @format, @extension = template_roots, format, extension
    end

    def template(template)
      template_path = path(template)
      raise UnknownTemplateError.new(@roots, template) if template_path.nil?

      Template.new(file_lexer(template_path)).tap do |template|
        template.path   = template_path
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

  # Converts a template string into a Template instance.
  #
  # Because a string template can only come from the engine instance
  # we need a FileLoader to delegate all future template loading to.
  class StringLoader < FileLoader
    def initialize(file_loader)
      @file_loader = file_loader
    end

    def template(template_string)
      Template.new(lexer(template_string)).tap do |template|
        template.loader = @file_loader
      end
    end
  end

  class CachedFileLoader < FileLoader
    def template_cache
      @template_cache ||= {}
    end

    def template(template)
      return template_cache[template] if template_cache.key?(template)
      template_cache[template] = super
    end
  end
end
