# encoding: UTF-8

require 'strscan'

module Cutaneous
  class Lexer
    attr_reader :template, :syntax

    def initialize(template, syntax)
      @template, @syntax = template, syntax
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
      scanner   = StringScanner.new(@template.to_s)
      tag_start = syntax.tag_start_pattern
      tags      = syntax.tags
      token_map = syntax.token_map
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
      expression.gsub!(syntax.escaped_tag_pattern, '\1')
      expression.gsub!(ESCAPE_STRING, '\\\\\&')
      [:text, expression]
    end
  end
end
