require_dependency 'issue'

module ApprovalPagePlugin
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        has_many :approval_items
        has_many :approvers, :through => :approval_items, :foreign_key => :user_id, :class_name => "User", :uniq => true
      end
    end

    module ClassMethods
    end

    module InstanceMethods

    end
  end
end
