module RuboCop

  module Cop

    module Tcg

      class StringHash < Base

        MSG = '`#hash` is randomized per process. Use `Zlib.crc32` or a `Digest` value ' \
              'for a seed, a cache key, or anything else that must repeat across runs.'.freeze

        RESTRICT_ON_SEND = %i[hash].freeze

        def on_send(node)
          return if node.receiver.nil?
          return unless node.arguments.empty?
          return if inside_a_hash_definition?(node)

          add_offense(node.loc.selector)
        end

        alias on_csend on_send

        private

        def inside_a_hash_definition?(node)
          node.each_ancestor(:def).any? { |definition| definition.method?(:hash) }
        end

      end

    end

  end

end
