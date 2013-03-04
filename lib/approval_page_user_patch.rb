require_dependency 'principal'
require_dependency 'issue'

module ApprovalPagePlugin
  module UserPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        has_many :approval_items
        has_many :approval_issues, :through => :approval_items, :foreign_key => :issue_id, :class_name => "Issue", :uniq => true
      end
    end

    module ClassMethods
    end

    module InstanceMethods

    end
  end
end
