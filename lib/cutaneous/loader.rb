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
      template = open_template(template) if String === template
      instance = @template_class.new(lexer(template))
      instance.path   = template.path if template.respond_to?(:path)
      instance.loader = self
      instance
    end

    def open_template(template)
      template_path = path(template)
      raise UnknownTemplateError.new(@roots, filename(template)) if template_path.nil?
      # TODO: Make the encoding configurable?
      TemplateReader.new(template_path, Encoding::UTF_8)
    end

    def lexer(template)
      Lexer.new(template, syntax)
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
      path = ::File.join(template_root, filename(template_name))
      ::File.exists?(path)
    end

    def location(template_root, template_name)
      return ::File.join(template_root, template_name) if exists?(template_root, template_name)
      nil
    end

    # An IO-like interface that provides #read and #path methods
    class TemplateReader
      def initialize(path, encoding)
        @path     = path
        @encoding = encoding
      end

      def read(*args)
        ::File.open(@path, 'r', external_encoding: @encoding) { |f| f.read }
      end

      def path
        @path
      end
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
      script = nil
      path = script_path
      if path && cached?
        script = File.read(path)
      else
        script = super
        write_cached_script(script, path) unless path.nil?
      end
      script
    end

    def cached?
      File.exist?(script_path) && (File.mtime(script_path) >= File.mtime(template_path))
    end

    def template_path
      path
    end

    def script_path
      @source_path ||= generate_script_path
    end

    def generate_script_path
      path = template_path
      return nil if path.nil?
      ext  = File.extname path
      path.gsub(/#{ext}$/, ".rb")
    end

    def write_cached_script(script, path)
      File.open(script_path, "w") do |f|
        f.write(script)
      end
    end
  end
end
