module RuboCop

  module Cop

    module Tcg

      class NoDecisionReferencesInComments < Base

        MSG = 'Comment refers to a decision or to where one is recorded (%<match>s). ' \
              'State the constraint itself, not its history.'.freeze

        DEFAULT_PATTERNS = [
          '\b[A-Z]{1,2}-\d+\b',
          '(?<![\w&#])#\d+\b',
          '\bdecisions?\b',
          '\btickets?\b',
          '\breview round\b',
          '\bfinding \d+\b',
          '\bsupersed\w*\b'
        ].freeze

        DIRECTIVE = /\A#\s*(?:rubocop:|frozen_string_literal:|encoding:|coding:|shareable_constant_value:|!)/

        def on_new_investigation
          processed_source.comments.each do |comment|
            next if comment.text.match?(DIRECTIVE)

            match = forbidden.match(comment.text)
            next unless match

            add_offense(offense_range(comment, match), message: format(MSG, match: match[0]))
          end
        end

        private

        def forbidden
          @forbidden ||= Regexp.union(patterns.map { |source| Regexp.new(source, Regexp::IGNORECASE) })
        end

        def patterns
          cop_config.fetch('ForbiddenPatterns', DEFAULT_PATTERNS)
        end

        def offense_range(comment, match)
          comment.source_range.adjust(begin_pos: match.begin(0)).resize(match[0].length)
        end

      end

    end

  end

end
