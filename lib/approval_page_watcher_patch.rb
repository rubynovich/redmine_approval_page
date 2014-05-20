module ApprovalPagePlugin
  module WatcherPatch
    extend ActiveSupport::Concern
    included do
      attr_writer :is_approver_not_approved
      attr_writer :is_approver
      before_destroy :break_destroy_approver
    end

    def is_approver_not_approved
      if self.watchable.kind_of?(Issue)
        return @is_approver || self.watchable.approval_items.where(["user_id = ? and approved in (?)", user_id, [nil,false]]).first.present?
      else
        return @is_approver
      end
    end

    def is_approver
      if self.watchable.kind_of?(Issue)
        return @is_approver || self.watchable.approval_items.where(user_id: user_id).first.present?
      else
        return @is_approver
      end
    end

    private
    def break_destroy_approver
      if is_approver_not_approved
        self.errors.add(:is_approver, :watcher_is_approver)
        return false
      end
      true
    end



  end
end