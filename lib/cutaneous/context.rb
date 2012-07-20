require 'delegate'

module Cutaneous
  class Context < Delegator
    attr_accessor :__buf, :__loader, :__target

    def initialize(target, locals = {})
      super(target)
      @__target, @__locals = target, locals
    end

    def __setobj__(obj)
      @__target = obj
    end

    def __getobj__
      @__target
    end

    def __decode_params(params)
      params.to_s
    end

    def escape(value)
      value
    end

    def include(template_name, locals = {})
      context = self.dup.__update_with_hash(locals)
      self.__buf  << __loader.template(template_name).render(context)
    end

    def respond_to?(name)
      return true if @__locals.key?(name.to_s) || @__locals.key?(name.to_sym)
      super
    end

    def method_missing(name, *args)
      return @__locals[name.to_s]   if @__locals.key?(name.to_s)
      return @__locals[name.to_sym] if @__locals.key?(name.to_sym)
      super
    end

    def __update_with_hash(locals)
      @__locals.update(locals)
      self
    end
  end
end
