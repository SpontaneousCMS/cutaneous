$:.push File.expand_path("../../lib", __FILE__)

require 'minitest/spec'
require 'minitest/autorun'

require 'cutaneous'

class TestContext < Cutaneous::Context
  def escape(value)
    value.gsub(/</, "&lt;").gsub(/>/, "&gt;")
  end
end

class MiniTest::Spec
  def ContextHash(params = {})
    TestContext.new(Object.new, params)
  end
end
