module ActiveRecord
  module Pull
    module Alpha
      module Core
        class << self
          def pull_many(records, q)
            records.map { |r| pull(r, q) }
          end
      
          def pull(record, q)
            case q
            when :*, '*'
              pull_all(record)
            when Symbol, String
              pull_symbol(record, q)
            when Hash
              pull_hash(record, q)
            when Array
              q.map { |pat| pull(record, pat) }.reduce(&:merge)
            else
              raise "Invalid pull syntax: #{q.inspect}"
            end
          end
        
          private
      
          def resolved_value(record, attr)
            if !(val = record[attr]).nil?
              val
            elsif val.nil? and !(reflection = record.class.reflect_on_association(attr)).nil?
              model = reflection.class_name.constantize
              p model
              case reflection
              when ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::HasAndBelongsToManyReflection
                model.where(reflection.foreign_key => record[record.class.primary_key])
              when ActiveRecord::Reflection::BelongsToReflection
                model.find_by(model.primary_key => record[reflection.foreign_key])
              else
                raise "Don't know how to resolve value for reflection: #{reflection.inspect}"
              end
            else
              nil
            end
          end
        
          def ref_type?(value)
            value.is_a?(ActiveRecord::Relation) || value.is_a?(ActiveRecord::Base)
          end
        
          def pull_symbol(record, attr)
            val = resolved_value(record, attr)
            if ref_type?(val) && val.is_a?(Enumerable)
              { attr => val.map { |v| pull_all(v) } }
            elsif ref_type?(val)
              { attr => pull_all(val) }
            else
              { attr => val }
            end
          end
        
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
        
          # TODO: this should pull all associations
          def pull_all(record)
            names  = record.class.attribute_names
            nested = record.class.nested_attributes_options
            attrs  = pull(record, names)
        
            if nested.empty?
              attrs
            else
              nested.keys.reduce(attrs) do |h, assoc|
                assoc_val = record.send(assoc)
                if assoc_val.nil? || assoc_val.is_a?(Enumerable) && assoc_val.empty?
                  h
                elsif assoc_val.is_a?(Enumerable)
                  h.merge!(assoc => assoc_val.map { |rec| pull_all(rec) }.reject(&:nil?))
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
end
