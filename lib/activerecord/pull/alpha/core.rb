# frozen_string_literal: true

module ActiveRecord
  module Pull
    module Alpha
      class SyntaxError < RuntimeError; end
      class ReflectionError < RuntimeError; end

      module Core

        class << self
          # Apply the pull query to a collection of records.
          #
          # @param records [Enumerable<ActiveRecord::Base>]
          # @param query [Symbol, String, Hash, Array]
          #
          # @return [Array<Hash>]
          def pull_many(records, query)
            records.map { |r| pull(r, query) }
          end

          # Apply the pull query to the given record.
          #
          # @param record [ActiveRecord::Base]
          # @param query [Symbol, String, Hash, Array]
          #
          # @return [Hash]
          def pull(record, query)
            case query
            when :*, '*'
              pull_all(record)
            when Symbol, String
              pull_symbol(record, query)
            when Hash
              pull_hash(record, query)
            when Array
              # TODO: add filter_map as a core extension for older Ruby implementations
              query.map { |pat| pull(record, pat) }.reduce(&:merge)
            else
              raise SyntaxError, "invalid pull syntax: #{query.inspect}"
            end
          end

          private

          EMPTY_HASH = {}.freeze
          private_constant :EMPTY_HASH

          R = ActiveRecord::Reflection
          private_constant :R

          # @param record [#[]]
          # @param attr [Symbol, String]
          #
          # @return [ActiveRecord::Base, ActiveRecord::Relation, Object, nil]
          def resolved_value(record, attr)
            val = record[attr]
            return val unless val.nil?

            reflection = record.class.reflect_on_association(attr)
            return if reflection.nil?

            model = reflection.class_name.constantize

            case reflection
            when R::HasManyReflection, R::HasAndBelongsToManyReflection
              model.where(reflection.foreign_key => record[record.class.primary_key])
            when R::BelongsToReflection
              model.find_by(model.primary_key => record[reflection.foreign_key])
            else
              raise ReflectionError, "don't know how to resolve value for reflection: #{reflection.inspect}"
            end
          end

          def ref_type?(value)
            value.is_a?(ActiveRecord::Relation) || value.is_a?(ActiveRecord::Base)
          end

          # @param record [#[]]
          # @param attr [Symbol, String]
          #
          # @return [Hash]
          def pull_symbol(record, attr)
            attr = attr.to_sym
            val  = resolved_value(record, attr)
            return EMPTY_HASH if val.nil?

            if ref_type?(val) && val.is_a?(Enumerable)
              { attr => val.map { |v| pull_all(v) } }
            elsif ref_type?(val)
              { attr => pull_all(val) }
            else
              { attr => val }
            end
          end

          # @param record [#[]]
          # @param hash [Hash{Symbol, String => Symbol, String, Hash, Array}]
          #
          # @return [Hash]
          def pull_hash(record, hash)
            hash.reduce({}) do |h, (attr, pat)|
              val = resolved_value(record, attr)
              if val.nil?
                h
              elsif ref_type?(val) && val.is_a?(Enumerable)
                h.merge!(attr => val.map { |v| pull(v, pat) })
              elsif ref_type?(val)
                h.merge!(attr => pull(val, pat))
              else
                h.merge!(attr => val)
              end
            end
          end

          # @param [ActiveRecord::Base]
          #
          # @return [Hash]
          def pull_all(record)
            names  = record.class.attribute_names.map(&:to_sym)
            nested = record.class.nested_attributes_options
            attrs  = pull(record, names)

            return attrs if nested.empty?

            nested.keys.reduce(attrs) do |h, assoc|
              assoc_val = record.send(assoc)
              if assoc_val.nil? || assoc_val.is_a?(Enumerable) && assoc_val.empty?
                h
              elsif assoc_val.is_a?(Enumerable)
                h.merge!(assoc => assoc_val.filter_map { |rec| pull_all(rec) })
              else
                h.merge!(assoc => pull_all(assoc_val))
              end
            end
          end
        end
      end
    end
  end
end
