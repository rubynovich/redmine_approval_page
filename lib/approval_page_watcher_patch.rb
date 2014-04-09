module ApprovalPagePlugin
  module WatcherPatch
    extend ActiveSupport::Concern
    included do
      attr_accessor :is_approver
    end
  end
end