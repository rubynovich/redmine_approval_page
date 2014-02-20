# -*- coding: utf-8 -*-
require_dependency 'issue'

module ApprovalPagePlugin
  module MailerPatch
    def self.included(base)

      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      base.class_eval do
        
        include Rails.application.routes.url_helpers

      end

    end

    module ClassMethods

      def approve_requests

        approval_items_per_user = ApprovalItem.where(approved: nil).group_by(&:user_id)

        for user_id, approval_items in approval_items_per_user
          issues = approval_items.map(&:approval_issue).compact
          user = User.find(user_id)
          mail_approve_request(user, issues).deliver
        end

      end

    end

    module InstanceMethods

      def mail_approve_request(user, issues)
        set_language_if_valid user.language

        @issues = issues
        issues_count = @issues.count

        @conjugation = case issues_count
                         when 1    then 1
                         when 2..4 then 2
                         else           5
                       end

        @subject = l(:"#{@conjugation}", scope: "mail_subject_approval_items", :count => issues_count)
        @body = l(:"#{@conjugation}", scope: "mail_body_approval_items", :count => issues_count)

        @username = user.name

        mail(to: user.mail, subject: @subject)

      end

      def approver_approved(user, issue, approver)
        set_language_if_valid user.language
        @user = user
        @issue = issue
        @issue_title = "##{@issue.id} \"#{@issue.subject}\""
        @approver = approver
        mail :to => user.mail, 
             :subject => l(:subject_approver_approved, approver: @approver, issue: @issue_title)
      end

      def approver_added(user, issue, approvers)
        set_language_if_valid user.language
        @user = user
        @issue = issue
        @issue_title = "##{@issue.id} \"#{@issue.subject}\""
        @approvers = approvers
        mail :to => user.mail, 
             :subject => l(:subject_approver_added, issue: @issue_title) + ': ' + approvers.join(', ')
      end

      def approver_removed(user, issue, approver)
        set_language_if_valid user.language
        @user = user
        @issue = issue
        @issue_title = "##{@issue.id} \"#{@issue.subject}\""
        @approver = approver
        mail :to => user.mail, :subject => l(:subject_approver_removed, issue: @issue_title, approver: @approver)
      end

      def you_are_approver(user, issue)
        set_language_if_valid user.language
        @issue = issue
        mail :to => user.mail, :subject => l(:subject_you_are_approver, issue: "##{issue.id} #{@issue.subject}")
      end

      def you_are_not_approver(user, issue)
        set_language_if_valid user.language
        @issue = issue
        mail :to => user.mail, :subject => l(:subject_you_are_not_approver, issue: "##{issue.id} #{@issue.subject}")
      end

    end
  end
end
