$:.push File.expand_path("../../lib", __FILE__)

require 'minitest/spec'
require 'minitest/autorun'

require 'cutaneous'

require 'stringio'

class TestContext < Cutaneous::Context
end

class MiniTest::Spec
  def ContextHash(params = {}, parent = nil)
    TestContext.new(Object.new, params, parent)
  end
end
