require_dependency 'issue'

module ApprovalPagePlugin
  module IssuePatch
    def self.included(base)
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        has_many :approval_items
        has_many :approvers, :through => :approval_items, :foreign_key => :user_id, :class_name => "User", :uniq => true

        validate :all_approved, :if => "!Issue.find(self.id).closed? && self.closed?"
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def all_approved
        return if approval_items.all?(&:approved?)
        errors.add :base, I18n.t(:error_you_cant_close_issue_without_approval)
      end
    end
  end
end
