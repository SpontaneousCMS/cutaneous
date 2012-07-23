# encoding: UTF-8

module Cutaneous
  class Syntax
    attr_reader :tags

    def initialize(tag_definitions)
      @tags = tag_definitions
    end

    def is_dynamic?(text)
      !text.index(tag_start_pattern).nil?
    end

    def tag_start_pattern
      @tag_start_pattern ||= compile_start_pattern
    end

    def escaped_tag_pattern
      @escaped_tag_pattern ||= compile_start_pattern_with_prefix("\\\\")
    end

    def compile_start_pattern
      not_escaped = "(?<!\\\\)"
      compile_start_pattern_with_prefix(not_escaped)
    end

    def compile_start_pattern_with_prefix(prefix)
      openings = self.tags.map { |type, tags| Regexp.escape(tags[0]) }
      Regexp.new("#{prefix}(#{ openings.join("|") })")
    end

    # map the set of tags into a hash used by the parse routine that converts an opening tag into a
    # list of: tag type, the number of opening braces in the tag and the length of the closing tag
    def token_map
      @token_map ||= Hash[tags.map { |type, tags| [tags[0], [type, tags[0].count(?{), tags[1].length]] }]
    end
  end
end
