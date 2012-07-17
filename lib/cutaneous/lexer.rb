# encoding: UTF-8

require 'strscan'

module Cutaneous
  class Lexer
    class << self
      attr_accessor :tags
    end

    module ClassMethods
      def generate(tag_definitions)
        parser_class = Class.new(Cutaneous::Lexer)
        parser_class.tags = tag_definitions
        parser_class
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

    extend ClassMethods

    def initialize(template)
      @template = template
    end

    def tokens
      @tokens ||= parse
    end

    # def script
    #   @script ||= compile
    # end

    protected

    BRACES ||= /\{|\}/
    STRIP_WS = "-"

    def parse
      tokens    = []
      scanner   = StringScanner.new(@template)
      tag_start = self.class.tag_start_pattern
      tags      = self.class.tags
      token_map = self.class.token_map
      previous  = nil

      while (text = scanner.scan_until(tag_start))
        tag = scanner.matched
        type, brace_count, endtag_length = token_map[tag]
        text.slice!(text.length - tag.length, text.length)
        expression = ""
        strip_whitespace = false

        begin
          expression << scanner.scan_until(BRACES)
          brace = scanner.matched
          brace_count += ((123 - brace.ord)+1) # '{' = 1,  '}' = -1
        end while (brace_count > 0)

        length = expression.length
        expression.slice!(length - endtag_length, length)

        if expression.end_with?(STRIP_WS)
          strip_whitespace = true
          length = expression.length
          expression.slice!(length - 1, length)
        end

        tokens << place_text_token(text) if text.length > 0
        tokens << create_token(type, expression, strip_whitespace)
        previous = type
      end
      tokens << place_text_token(scanner.rest) unless scanner.eos?
      tokens
    end

    def create_token(type, expression, strip_whitespace)
      [type, expression, strip_whitespace]
    end

    #BEGINNING_WHITESPACE ||= /\A\s*?[\r\n]+/
    #ENDING_WHITESPACE    ||= /(\r?\n)[ \t]*\z/
    ESCAPE_STRING        ||= /[`\\]/

    def place_text_token(expression)
      expression.gsub!(self.class.escaped_tag_pattern, '\1')
      expression.gsub!(ESCAPE_STRING, '\\\\\&')
      [:text, expression]
    end
  end

  PublishLexer = Cutaneous::Lexer.generate({
    :comment => %w(!{ }),
    :expression => %w(${ }),
    :escaped_expression => %w($${ }),
    :statement => %w(%{ })
  })

  RequestLexer = Cutaneous::Lexer.generate({
    :comment => %w(!{ }),
    :expression => %w({{ }}),
    :escaped_expression => %w({$ $}),
    :statement => %w({% %})
  })
end
