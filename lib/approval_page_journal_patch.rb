module ApprovalPagePlugin
  module JournalPatch
    extend ActiveSupport::Concern
    included do
      attr_accessor :approvers
      attr_accessor :approvals_action #:add, :destroy
    end
  end
end