module Cutaneous
  class Template
    attr_accessor :loader, :lexer, :path

    def initialize(lexer)
      @lexer = lexer
    end

    def compiler
      @compiler ||= Compiler.new(lexer, loader)
    end

    def render(context)
      context.__loader = loader
      context.instance_eval(&template_proc)
    end

    def template_proc
      @template_proc ||= eval(template_proc_src, nil, path || "(cutaneous)")
    end

    def template_proc_src
      "lambda { |context| self.__buf = __buf = ''; #{compiler.script}; __buf.to_s }"
    end

    def block_order
      compiler.block_order
    end

    def block(block_name)
      compiler.block(block_name)
    end
  end
end
