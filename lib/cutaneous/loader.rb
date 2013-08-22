module Cutaneous
  # Converts a template path or Proc into a Template instance for a particular format
  class FileLoader
    attr_accessor :syntax
    attr_writer   :template_class
    attr_reader   :format

    def initialize(template_roots, format, extension = Cutaneous.extension)
      @roots, @format, @extension = template_roots, format, extension
      @template_class = Template
    end

    def render(template, context)
      template(template).render(context)
    end

    def convert(template, to_syntax)
      template(template).convert(to_syntax)
    end

    def template(template)
      return proc_template(template) if template.is_a?(Proc)
      template_path = path(template)
      raise UnknownTemplateError.new(@roots, filename(template)) if template_path.nil?

      @template_class.new(file_lexer(template_path)).tap do |template|
        template.path   = template_path
        template.loader = self
      end
    end

    def proc_template(lmda)
      StringLoader.new(self).template(lmda.call)
    end

    def file_lexer(template_path)
      lexer(SourceFile.new(template_path))
    end

    def lexer(template_string)
      Lexer.new(template_string, syntax)
    end

    def path(template_name)
      filename = filename(template_name)
      return filename if ::File.exists?(filename) # Test for an absolute path
      @roots.map { |root| ::File.join(root, filename)}.detect { |path| ::File.exists?(path) }
    end

    def filename(template_name)
      [template_name, @format, @extension].join(".")
    end

    def exists?(template_root, template_name)
      File.exists?(File.join(template_root, filename(template_name)))
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

    def syntax
      @file_loader.syntax
    end

    def template(template_string)
      Template.new(lexer(template_string)).tap do |template|
        template.loader = @file_loader
      end
    end
  end

  # Converts a filepath to a template string as and when necessary
  class SourceFile
    attr_reader :path

    def initialize(filepath)
      @path = filepath
    end

    def to_s
      File.read(@path)
    end
  end

  # Caches Template instances
  class CachedFileLoader < FileLoader
    def initialize(template_roots, format, extension = Cutaneous.extension)
      super
      @template_class = CachedTemplate
    end

    def template_cache
      @template_cache ||= {}
    end

    def write_compiled_scripts=(flag)
      if flag
        @template_class = CachedTemplate
      else
        @template_class = Template
      end
    end

    def template(template)
      return template_cache[template] if template_cache.key?(template)
      template_cache[template] = super
    end
  end

  # Provides an additional caching mechanism by writing generated template
  # scripts to a .rb file.
  class CachedTemplate < Template

    def script
      if cached?
        script = File.read(script_path)
      else
        script = super
        File.open(script_path, "w") do |f|
          f.write(script)
        end
      end
      script
    end

    def cached?
      File.exist?(script_path) && (File.mtime(script_path) >= File.mtime(template_path))
    end

    def template_path
      lexer.template.path
    end

    def script_path
      @source_path ||= generate_script_path
    end

    def generate_script_path
      path = template_path
      ext  = File.extname path
      path.gsub(/#{ext}$/, ".rb")
    end
  end
end
