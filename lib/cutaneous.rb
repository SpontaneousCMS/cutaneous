require 'cutaneous/engine'
require 'cutaneous/template'
require 'cutaneous/loader'
require 'cutaneous/context'
require 'cutaneous/lexer'
require 'cutaneous/compiler'

module Cutaneous
  VERSION = "0.0.1.alpha.1"

  class CompilationError < Exception; end

  class UnknownTemplateError < Exception
    def initialize(template_roots, relative_path)
      super("Template '#{relative_path}' not found under #{template_roots.inspect}")
    end
  end

  def self.extension
    "cut"
  end
end
