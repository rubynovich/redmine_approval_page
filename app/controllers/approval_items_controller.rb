# -*- coding: utf-8 -*-

class ApprovalItemsController < ApplicationController
  unloadable
  before_filter :find_issue, :only => [:new, :create, :autocomplete_for_user, :card]

  helper :journals
  helper :issues
  helper :watchers

  def new
    @show_form = "true"
    @users = User.active.sorted.all(limit: 100)
    @users -= @issue.approvers
  end

  def create
    approvers = []

    flash.now[:notice] = l(:notice_successful_create) if params[:approver] && User.find(params[:approver][:user_ids]).all? do |user|
      if approval_item = ApprovalItem.create(:approver => user, :approval_issue => @issue)
        Mailer.you_are_approver(approval_item.approver, @issue).deliver
        approvers << approval_item.approver.name
      end
    end

    Mailer.with_deliveries(false) do
      journal = @issue.init_journal(User.current, ::I18n.t(:message_add_approver, :names => approvers.join(", ").html_safe))
      journal.save
    end
    
    # Автору и исполнителю согласуемой задачи вотчи о удалении
    # согласующих приходят всегда.
    recipients = [@issue.author, @issue.assigned_to].uniq
    if recipients.include?(User.current) && User.current.pref.no_self_notified
        recipients = [@issue.author, @issue.assigned_to] - [User.current]
    end
    recipients.each{|r| Mailer.approver_added(r, @issue, approvers).deliver }

    @users = @issue.approvers
    @journals = get_journals

    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

  def update
    item = ApprovalItem.find(params[:id])
    flash.now[:notice] = l(:notice_successful_update) if !item.approval_issue.closed? && item.update_attributes(params[:approval_item])

    find_issue
    @users = @issue.approvers
    @journals = get_journals

    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

  def destroy
    item = ApprovalItem.find(params[:id])

    flash.now[:notice] = l(:notice_successful_delete) if item.destroy

    find_issue
    @users = @issue.approvers
    @journals = get_journals

    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end

  def autocomplete_for_user
    @users = User.active.like(params[:q]).sorted.all(limit: 100)
    @users -= @issue.approvers

    render :layout => false
  end

  def card
    @collection = @issue.approval_items.includes(:approver).order("users.lastname, users.firstname")
  end

  private
    def find_issue
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def get_journals
      journals = @issue.journals.includes(:user, :details).reorder("#{Journal.table_name}.id ASC").all
      journals.each_with_index {|j,i| j.indice = i+1}
      journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
      journals.reverse! if User.current.wants_comments_in_reverse_order?
      journals
    end
end
