require 'activerecord/pull/alpha/core'

module Enumerable
  def pull(*pattern)
    ActiveRecord::Pull::Alpha::Core.pull_many(self, pattern)
  end
end

class Object
  def pull(*pattern)
    ActiveRecord::Pull::Alpha::Core.pull(self, pattern)
  end
end
