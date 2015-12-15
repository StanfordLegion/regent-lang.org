# -*- coding: utf-8 -*- #

require 'rouge'

module Rouge
  module Lexers
    class Regent < Lua
      title "Regent"
      desc "Regent (https://github.com/StanfordLegion/legion/tree/master/language)"
      tag 'regent'
      filenames '*.rg'

      state :base do
        # Lua syntax:
        rule %r(--\[(=*)\[.*?\]\1\])m, Comment::Multiline
        rule %r(--.*$), Comment::Single

        rule %r((?i)(\d*\.\d+|\d+\.\d*)(e[+-]?\d+)?'), Num::Float
        rule %r((?i)\d+e[+-]?\d+), Num::Float
        rule %r((?i)0x[0-9a-f]*), Num::Hex
        rule %r(\d+), Num::Integer

        rule %r(\n), Text
        rule %r([^\S\n]), Text
        # multiline strings
        rule %r(\[(=*)\[.*?\]\1\])m, Str

        rule %r((==|~=|<=|>=|\.\.\.|\.\.|[=+\-*/%^<>#])), Operator
        rule %r([\[\]\{\}\(\)\.,:;]), Punctuation
        rule %r((and|or|not)\b), Operator::Word

        rule %r((break|do|else|elseif|end|for|if|in|repeat|return|then|until|while)\b), Keyword
        rule %r((local)\b), Keyword::Declaration
        rule %r((true|false|nil)\b), Keyword::Constant

        rule %r((function)\b), Keyword, :function_name

        # Regent syntax:
        rule %r([@]), Operator
        rule %r((atomic|copy|equal|exclusive|fill|import|new|null|reads|reduces|relaxed|simultaneous|where|writes)\b), Keyword
        rule %r((var)\b), Keyword::Declaration
        rule %r((ispace|ptr|partition|region)\b), Keyword::Type
        rule %r((task)\b), Keyword, :function_name
        rule %r((fspace|struct)\b), Keyword, :function_name

        # Lua syntax:
        rule %r([A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)?) do |m|
          name = m[0]
          if self.builtins.include?(name)
            token Name::Builtin
          elsif name =~ /\./
            a, b = name.split('.', 2)
            token Name, a
            token Punctuation, '.'
            token Name, b
          else
            token Name
          end
        end

        rule %r('), Str::Single, :escape_sqs
        rule %r("), Str::Double, :escape_dqs
      end
    end
  end
end
