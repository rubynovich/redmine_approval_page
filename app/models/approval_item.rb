# -*- coding: utf-8 -*-
class ApprovalItem < ActiveRecord::Base
  unloadable

  validates_presence_of :issue_id, :user_id
  validates_presence_of :approved_on, :if => "approved?"
  validates_uniqueness_of :issue_id, :scope => :user_id
  validates_uniqueness_of :user_id,  :scope => :issue_id

  belongs_to :approver, :foreign_key => :user_id, :class_name => "User"
  belongs_to :approval_issue, :foreign_key => :issue_id, :class_name => "Issue"

  before_validation :add_approved_on, :if => "approved? && !ApprovalItem.find(id).approved?"
  before_update :message_approver_approved, :if => "approved? ^ ApprovalItem.find(id).approved?"
  after_update :set_finish_status
  after_destroy :set_finish_status
  after_create :message_add_approver
  after_create :set_default_status, if: -> { (self.approval_issue.status == IssueStatus.find(Setting[:plugin_redmine_approval_page][:issue_status])) }
  before_destroy :message_remove_approver

  private
    def add_approved_on
      self.approved_on = Time.now
    end

    def message_add_approver
#      set_start_status if issue.closed?
      Watcher.create(:watchable => self.approval_issue, :user => self.approver, :is_approver => true)
    end

    def message_remove_approver
      issue = self.approval_issue
      if issue

        approvers_without_self = issue.approval_items-[self]
        Mailer.with_deliveries(false) do  
          journal = issue.init_journal(User.current, ::I18n.t(:message_remove_approver, :name => self.approver.name))
          journal.approver_ids = [self.approver.id].uniq
          journal.save
        end

        # Согласующий удалил сам себя? Указано ли у него в настройках,
        # что он хочет получать вотчи о своих собственных действиях? 
        if User.current != self.approver || !self.approver.pref.no_self_notified
          Mailer.you_are_not_approver(self.approver, self.approval_issue).deliver
        end
        
        # Автору и исполнителю согласуемой задачи вотчи о удалении
        # согласующих приходят всегда.
        recipients = [issue.author, issue.assigned_to].uniq
        if recipients.include?(User.current) && User.current.pref.no_self_notified
          recipients = [issue.author, issue.assigned_to] - [User.current]
        end

        for recipient in recipients
          Mailer.approver_removed(recipient, issue, self.approver.name).deliver
        end

      end
    end

    def message_approver_approved
      delta = self.approved? ? 1 : -1
      issue = self.approval_issue
      approvers_without_self = issue.approval_items-[self]

      Mailer.with_deliveries(false) do
        journal = issue.init_journal(User.current, ::I18n.t('message_approver_approved')[approved?])
        journal.save
      end

      # Вотчи о согласовании задачи приходят автору, исполнителю и наблюдателям.
      recipients = [issue.author, issue.assigned_to] | issue.watchers.map(&:user)
      Rails.logger.error recipients.map{|r| [r.inspect.split(':').first, r.try(:name)] }.inspect.red
      if recipients.include?(User.current) && User.current.pref.no_self_notified
        recipients = recipients - [User.current]
      end
      for recipient in recipients
        Mailer.approver_approved(recipient, issue, self.approver.name).deliver
      end


    end


    def set_finish_status
      if !self.approval_issue.closed? && self.approval_issue.approval_items.present? && self.approval_issue.approval_items.all?(&:approved)
        self.approval_issue.init_journal(User.current, ::I18n.t(:message_issue_approved))
        self.approval_issue.update_attribute(:status_id, Setting[:plugin_redmine_approval_page][:issue_status])
        self.approval_issue.approval_items.each do |item|
          Watcher.where(:watchable_type => "Issue", :watchable_id => self.approval_issue, :user_id => item.approver).delete_all
        end
      end
    end

    def set_default_status
      self.approval_issue.update_attributes(status: IssueStatus.default)
    end
end
