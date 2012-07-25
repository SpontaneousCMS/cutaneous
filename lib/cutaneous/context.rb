require 'delegate'
require 'cgi'

module Cutaneous
  class Context < Delegator
    attr_accessor :__buf, :__loader, :__target, :__locals

    def initialize(target, locals_or_context = {})
      super(target)
      @__target, @__locals = target, {}
      __update_context(locals_or_context)
    end

    def __decode_params(params)
      params.to_s
    end

    def escape(value)
      CGI::escapeHTML(value)
    end

    def include(template_name, locals = {})
      context = self.dup.__update_with_locals(locals)
      self.__buf  << __loader.template(template_name).render(context)
    end

    def respond_to_missing?(name, include_private = false)
      return true if @__locals.key?(name.to_s) || @__locals.key?(name.to_sym)
      super
    end

    def respond_to?(name, include_private = false)
      return true if @__locals.key?(name.to_s) || @__locals.key?(name.to_sym)
      super
    end

    def method_missing(name, *args)
      return @__locals[name.to_s]   if @__locals.key?(name.to_s)
      return @__locals[name.to_sym] if @__locals.key?(name.to_sym)
      super
    rescue NameError => e
      __handle_error(e)
    end

    def __handle_error(e)
      # Default behaviour is to silently discard errors
    end

    def __update_context(parent)
      case parent
      when Hash
        __update_with_locals(parent)
      when Cutaneous::Context
        parent.instance_variables.reject { |var| /^@__/o === var.to_s }.each do |variable|
          instance_variable_set(variable, parent.instance_variable_get(variable))
        end
        __update_with_locals(parent.__locals) if parent.respond_to?(:__locals)
      end
    end

    # Sets up the local variables and also creates singleton methods on this
    # instance so that the local values will override any method implementations
    # on the context itself. i.e.:
    #
    # class MyContext < Cutanteous::Context
    #   def monkey
    #     "puzzle"
    #   end
    # end
    #
    # context = MyContext.new(Object.new, monkey: "magic")
    #
    # context.monkey #=> "magic" not "puzzle"
    #
    def __update_with_locals(locals)
      @__locals.update(locals)
      singleton = singleton_class
      locals.each do |name, value|
        singleton.__send__(:define_method, name) { value }
      end
      self
    end

    # Required by the Delegator class
    def __setobj__(obj)
      @__target = obj
    end

    # Required by the Delegator class
    def __getobj__
      @__target
    end
  end
end
