require 'cutaneous/compiler/expression'

module Cutaneous
  class Compiler
    # A single named block of template expressions
    class Block
      attr_reader :name

      def initialize(name)
        @name        = name
        @expressions = []
      end

      def push(expression)
        @expressions << expression
      end

      alias_method :<<, :push

      def to_script
        script = ""
        @expressions.each do |expression|
          script << expression.to_script
        end
        script
      end
    end

    # Represents the block structure of a top-level master template,
    # i.e. one with no `extends` call.
    class BlockSet
      attr_reader   :current_block
      attr_accessor :loader

      def initialize
        @block_order = []
        @block_store = {}
        block_start
      end

      def block_start(name = Object.new)
        @current_block = Block.new(name)
        @block_order << name
        @block_store[name] = @current_block
      end

      def block_end
        block_start
      end

      def push(tag)
        @current_block << tag
      end

      def block_order
        @block_order
      end

      def super_block
        raise CompilationError.new("Invalid 'blocksuper' call from top-level template")
      end

      def block(name)
        @block_store[name]
      end

      def each_block
        block_order.each do |block_name|
          yield block(block_name)
        end
      end

      def to_script
        script = ""
        each_block do |block|
          script << block.to_script
        end
        script
      end
    end

    # Represents the block structure of a sub-template that inherits its
    # block structure from some parent template defined by an `extends`
    # tag.
    class ExtendedBlockSet < BlockSet
      def initialize(template_name)
        @super_template_name = template_name
        super()
      end

      def super_template
        @super_template ||= @loader.template(@super_template_name)
      end

      def super_block
        super_template.block(current_block.name)
      end

      def block(name)
        return @block_store[name] if @block_store.key?(name)
        super_template.block(name)
      end

      def block_order
        super_template.block_order
      end
    end

    # Converts a list of expressions into either a master or child block
    # set.
    class BlockBuilder
      def initialize(loader)
        @loader = loader
        assign_block_set(BlockSet.new)
      end

      def build(expressions)
        expressions.each do |expression|
          expression.affect(self)
        end
        @block_set
      end

      def extends(parent)
        assign_block_set(ExtendedBlockSet.new(parent))
      end

      def assign_block_set(block_set)
        @block_set = block_set
        @block_set.loader = @loader
      end

      def current_block
        @block_set.current_block
      end

      def block_start(block_name)
        @block_set.block_start(block_name)
      end

      def block_end
        @block_set.block_end
      end

      def block_super
        push(super_block)
      end

      def push(tag)
        @block_set.push(tag)
      end

      def super_block
        @block_set.super_block
      end
    end

    def initialize(lexer, loader)
      @lexer, @loader = lexer, loader
    end


    def blocks
      @blocks ||= build_hierarchy
    end

    def build_hierarchy
      builder = BlockBuilder.new(@loader)
      builder.build(expressions)
    end

    def expressions
      expressions = []
      @lexer.tokens.each do |type, expression|
        case type
        when :text
          expressions << Text.new(expression)
        when :expression
          expressions << Expression.new(expression)
        when :escaped_expression
          expressions << EscapedExpression.new(expression)
        when :statement
          expressions << parse_statement(expression)
        when :comment
          expressions << Comment.new(expression)
        end
      end
      # We don't need this any more so release it
      @lexer = nil
      expressions
    end

    EXTENDS     = /\A\s*extends\s+["']([^"']+)["']\s*\z/o
    BLOCK_START = /\A\s*block\s+:?([a-zA-Z_][a-zA-Z0-9_]*)\s*\z/o
    BLOCK_END   = /\A\s*endblock(?:\s+:?[a-zA-Z_][a-zA-Z0-9_]*)?\s*\z/o
    BLOCK_SUPER = /\A\s*block_?super\s*\z/o

    def parse_statement(statement)
      case statement
      when EXTENDS
        Extends.new($1)
      when BLOCK_START
        BlockStart.new($1)
      when BLOCK_END
        BlockEnd.new
      when BLOCK_SUPER
        BlockSuper.new
      else
        Statement.new(statement)
      end
    end

    def script
      blocks.to_script
    end

    def block_order
      blocks.block_order
    end

    def block(name)
      blocks.block(name)
    end
  end
end
