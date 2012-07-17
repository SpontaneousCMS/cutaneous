module Cutaneous
  class Compiler
    class Expression
      def initialize(expression)
        @expression = expression
      end

      def to_script
        %{__buf << _decode_params((} << @expression << %{)) ; }
      end

      def affect(builder)
        builder.push(self)
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

    class Extends
      def initialize(template_name)
        @template_name = template_name
      end

      def affect(builder)
        builder.extends(@template_name)
      end
    end

    class BlockStart
      def initialize(block_name)
        @block_name = block_name.to_sym
      end

      def affect(builder)
        builder.block_start(@block_name)
      end
    end

    class BlockEnd
      def affect(builder)
        builder.block_end
      end
    end

    class BlockSuper
      def affect(builder)
        builder.block_super
      end
    end
  end
end
