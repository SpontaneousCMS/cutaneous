require 'cutaneous/engine'
require 'cutaneous/template_loader'
require 'cutaneous/context'
require 'cutaneous/template'
require 'cutaneous/lexer'
require 'cutaneous/compiler'

module Cutaneous
  VERSION = "0.0.1-alpha"

  class CompilationError < Exception; end
end
