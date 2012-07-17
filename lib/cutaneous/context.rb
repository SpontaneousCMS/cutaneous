require 'delegate'

module Cutaneous
  class Context < Delegator
    attr_accessor :__buf, :__loader

    def initialize(target, params = {})
      super(target)
      @__target, @__params = target, params
    end

    def __setobj__(obj)
      @__target = obj
    end

    def __getobj__
      @__target
    end

    def _decode_params(params)
      params.to_s
    end

    def escape(value)
      value
    end

    def include(template_name, params = {})
      context = self.dup.__update_with_hash(params)
      __buf <<  __loader.template(template_name).render(context)
    end

    def respond_to?(name)
      return true if @__params.key?(name.to_s) || @__params.key?(name.to_sym)
      super
    end

    def method_missing(name, *args)
      return @__params[name.to_s]   if @__params.key?(name.to_s)
      return @__params[name.to_sym] if @__params.key?(name.to_sym)
      super
    end

    def __update_with_hash(params)
      @__params.update(params)
      self
    end
  end
end