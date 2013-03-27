class ApprovalItem < ActiveRecord::Base
  unloadable

  validates_presence_of :issue_id, :user_id
  validates_presence_of :approved_on, :if => "approved?"
  validates_uniqueness_of :issue_id, :scope => :user_id
  validates_uniqueness_of :user_id,  :scope => :issue_id

  belongs_to :approver, :foreign_key => :user_id, :class_name => "User"
  belongs_to :approval_issue, :foreign_key => :issue_id, :class_name => "Issue"

  before_validation :add_approved_on, :if => "approved? && !ApprovalItem.find(id).approved?"
#  after_save :set_finish_status, :if => "!approval_issue.closed? && approval_issue.approval_items.all?(&:approved)"
  before_update :message_approver_approved, :if => "approved? ^ ApprovalItem.find(id).approved?"
  after_create :message_add_approver
  before_destroy :message_remove_approver

  private
    def add_approved_on
      self.approved_on = Time.now
    end

    def message_add_approver
      issue = self.approval_issue
      issue.init_journal(User.current, ::I18n.t(:message_add_approver, :name => self.approver.name))
      issue.save
#      set_start_status if issue.closed?
      Watcher.create(:watchable => self.approval_issue, :user => self.approver)
    end

    def message_remove_approver
      issue = self.approval_issue
      approvers_without_self = issue.approval_items-[self]
      issue.init_journal(User.current, ::I18n.t(:message_remove_approver, :name => self.approver.name))
      issue.save
      set_finish_status if !issue.closed? && approvers_without_self.present? && approvers_without_self.all?(&:approved)
      true
    end

    def message_approver_approved
      delta = self.approved? ? 1 : -1
      issue = self.approval_issue
      approvers_without_self = issue.approval_items-[self]
      issue.init_journal(User.current, ::I18n.t('message_approver_approved')[approved?])
      issue.save
      set_finish_status if !issue.closed? && self.approved? && approvers_without_self.all?(&:approved)
    end

    def set_finish_status
      self.approval_issue.init_journal(User.current, ::I18n.t(:message_issue_approved))
      self.approval_issue.update_attributes(:status_id => Setting[:plugin_redmine_approval_page][:issue_status])
    end
end
