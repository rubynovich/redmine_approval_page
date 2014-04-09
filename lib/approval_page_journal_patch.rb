module ApprovalPagePlugin
  module JournalPatch
    extend ActiveSupport::Concern
    included do
      attr_accessor :approver_ids
    end
  end
end