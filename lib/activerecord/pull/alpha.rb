require "activerecord/pull/alpha/core"
require "activerecord/pull/alpha/version"

module ActiveRecord
  class Base
    def pull(*pattern)
      ActiveRecord::Pull::Alpha::Core.pull(self, pattern)
    end
  end

  class Relation
    def pull(*pattern)
      ActiveRecord::Pull::Alpha::Core.pull_many(self, pattern)
    end
  end
end
