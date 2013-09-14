require 'cutaneous/engine'
require 'cutaneous/template'
require 'cutaneous/loader'
require 'cutaneous/context'
require 'cutaneous/syntax'
require 'cutaneous/lexer'
require 'cutaneous/compiler'

module Cutaneous
  VERSION = "0.1.6"

  class CompilationError < Exception; end

  class UnknownTemplateError < Exception
    def initialize(template_roots, relative_path)
      super("Template '#{relative_path}' not found under #{template_roots.inspect}")
    end
  end

  def self.extension
    "cut"
  end

  FirstPassSyntax = Cutaneous::Syntax.new({
    :comment => %w(!{ }),
    :expression => %w(${ }),
    :escaped_expression => %w($${ }),
    :statement => %w(%{ })
  })

  SecondPassSyntax = Cutaneous::Syntax.new({
    :comment => %w(!{ }),
    :expression => %w({{{ }}}),
    :escaped_expression => %w({{ }}),
    :statement => %w({% %})
  })
end
