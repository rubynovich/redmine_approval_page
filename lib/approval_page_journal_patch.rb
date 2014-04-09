module ApprovalPagePlugin
  module JournalPatch
    extend ActiveSupport::Concern
    included do
      attr_accessor :approver
    end
  end
end