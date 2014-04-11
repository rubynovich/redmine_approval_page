module ApprovalPagePlugin
  module JournalPatch
    extend ActiveSupport::Concern
    included do
      attr_accessor :approvers
      attr_accessor :approver_ids
      attr_accessor :approvals_action #:add, :destroy
    end

    def approvers
      @approvers ||= (self.approver_ids ? User.where(id: self.approver_ids) : [])
      @approvers
    end

  end
end