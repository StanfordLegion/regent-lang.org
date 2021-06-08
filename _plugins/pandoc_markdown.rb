# From https://github.com/elliottslaughter/jekyll-pandoc-plugin
module Jekyll
  module Converters
    class Markdown
      class Pandoc
        def initialize(config)
          Jekyll::External.require_with_graceful_fail "pandoc-ruby"
          @config = config["pandoc"] || {}
        end

        def convert(content)
          extensions = @config['extensions'] || []
          format = @config['format'] || 'html5'
          ::PandocRuby.new(content, *extensions).send("to_#{format}")
        end
      end
    end
  end
end
