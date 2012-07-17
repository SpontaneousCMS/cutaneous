module Cutaneous
  class Compiler
    def initialize(lexer, loader)
      @lexer, @loader = lexer, loader
    end

    class Expression
      def initialize(expression)
        @expression = expression
      end

      def to_script
        %{__buf << _decode_params((} << @expression << %{)) ; }
      end

      def visit(compiler)
        compiler.push(self)
      end
    end

    class EscapedExpression < Expression
      def to_script
        %{__buf << escape(_decode_params((} << @expression << %{))) ; }
      end
    end

    class Statement < Expression
      def to_script
        "" << @expression << " ; "
      end
    end

    class Text < Expression
      def to_script
        %(__buf << %Q`) << @expression << %(` ; )
      end
    end

    class Comment < Expression
      # Need to make sure that the line positions are the same
      def to_script
        @expression.lines.to_a[0..-2].map { |line| "\n" }.join
      end
    end

    # class BlockTree
    #   include Enumerable

    #   def initialize
    #     @statements = []
    #   end

    #   def push(statement)
    #     @statements << statement
    #   end

    #   alias_method :<<, :push

    #   def each(&block)
    #     @statements.each(&block)
    #   end
    # end
    class Extends
      def initialize(template)
        @template = template
      end

      def visit(compiler)
        compiler.make_child(@template)
      end
    end

    class BlockStart
      def initialize(name)
        @name = name.to_sym
      end
      def visit(compiler)
        compiler.template.start_block(@name)
      end
    end

    class BlockEnd
      def visit(compiler)
        compiler.template.end_block
      end
    end

    class BlockSuper
      def visit(compiler)
        @block = compiler.template.current_block
        @template = compiler.template
        compiler.push(self)
      end

      def to_script
        superblock = @template.block_super(@block.name)
        return "" if superblock.nil?
        superblock.to_script
      end
    end

    class Block
      attr_reader :name
      def initialize(name)
        @name = name
        @tree = []
      end

      def push(tag)
        @tree << tag
      end

      alias_method :<<, :push

      def to_script
        @tree.map { |tag| tag.to_script }.join
      end
    end

    class MasterTemplate
      attr_reader   :current_block
      attr_accessor :loader

      def initialize
        @block_order = []
        @block_store = {}
        start_block
      end

      def start_block(name = Object.new)
        @current_block = Block.new(name)
        @block_order << name
        @block_store[name] = @current_block
      end

      def end_block
        start_block
      end

      def push(tag)
        @current_block << tag
      end

      def block_order
        @block_order
      end

      def block_super(block_name)
        ""
      end

      def block(name)
        @block_store[name]
      end

      def to_script
        block_order.map { |block_name|
          block = self.block(block_name)
          block.to_script
        }.join
      end
    end

    class ChildTemplate < MasterTemplate
      def initialize(template_name)
        @super_template_name = template_name
        super()
      end

      def super_template
        @super_template ||= @loader.template(@super_template_name)
      end

      def block_super(block_name)
        super_template.block(block_name)
      end

      def block(name)
        return @block_store[name] if @block_store.key?(name)
        super_template.block(name)
      end

      def block_order
        super_template.block_order
      end
    end

    class CompiledTemplate
      attr_accessor :template

      def initialize(loader)
        @loader, @template = loader, MasterTemplate.new
        @template.loader = @loader
      end

      def make_child(parent)
        @template = ChildTemplate.new(parent)
        @template.loader = @loader
      end

      def add(tag)
        tag.visit(self)
      end

      def push(tag)
        @template.push(tag)
      end

      def to_script
        @template.to_script
      end

      def block_order
        @template.block_order
      end
      def block(name)
        @template.block(name)
      end
    end

    def compiled
      @compiled ||= build_block_tree
    end


    def build_block_tree
      tree = []
      @lexer.tokens.each do |type, expression|
        case type
        when :text
          tree << Text.new(expression)
        when :expression
          tree << Expression.new(expression)
        when :escaped_expression
          tree << EscapedExpression.new(expression)
        when :statement
          tree << statement(expression)
        when :comment
          tree << Comment.new(expression)
        end
      end
      compiled = CompiledTemplate.new(@loader)
      tree.each do |tag|
        compiled.add(tag)
      end
      compiled
    end

    def compile
      compiled.to_script
    end

    EXTENDS     = /\A\s*extends\s+["']([^"']+)["']\s*\z/o
    BLOCK_START = /\A\s*block\s+:?([a-zA-Z_][a-zA-Z0-9_]*)\s*\z/o
    BLOCK_END   = /\A\s*endblock(?:\s+:?[a-zA-Z_][a-zA-Z0-9_]*)?\s*\z/o
    BLOCK_SUPER = /\A\s*block_?super\s*\z/o

    def statement(statement)
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
      compile
    end

    def block_order
      compiled.block_order
    end

    def block(name)
      compiled.block(name)
    end
  end
end
