module ApprovalPagePlugin
  module JournalPatch
    extend ActiveSupport::Concern
    included do
      attr_accessor :approver_ids
      attr_accessor :approval_action #:add, :destroy
    end
  end
end