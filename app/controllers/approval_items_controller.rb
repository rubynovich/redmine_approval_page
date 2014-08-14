# -*- coding: utf-8 -*-

class ApprovalItemsController < ApplicationController
  unloadable
  before_filter :find_issue, :only => [:new, :create, :autocomplete_for_user, :card]

  helper :journals
  helper :issues
  helper :watchers


  accept_api_auth :create, :destroy, :update

  def new
    @show_form = "true"
    @users = User.active.sorted.all(limit: 100)
    @users -= @issue.approvers
  end

  def create
    approvers = []
    approver_ids = []

    old_approver_ids = @issue.approvers.map(&:id).uniq.sort

    flash.now[:notice] = l(:notice_successful_create) if params[:approver] && User.find(params[:approver][:user_ids]).all? do |user|
      if approval_item = ApprovalItem.create(:approver => user, :approval_issue => @issue)
        unless approval_item.approver == User.current && User.current.pref.no_self_notified
          Mailer.you_are_approver(approval_item.approver, @issue).deliver
        end
        approvers << approval_item.approver.name
        approver_ids << approval_item.approver.id
      end
    end

    Mailer.with_deliveries(false) do
      journal = @issue.init_journal(User.current, '')
      journal.approver_ids = approver_ids.uniq
      journal.approvals_action = :add
      new_approver_ids = (old_approver_ids + User.where(id: approver_ids).map(&:id)).uniq.sort
      journal.details.build(property: "watchers", prop_key: "approver", old_value: old_approver_ids.join(','), value: new_approver_ids.join(',') ) if new_approver_ids != old_approver_ids
      journal.save!
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
      format.api { render_api_ok }
    end
  end

  def update
    approval_item_params = params[:approval_item] || params[:approver]
    find_issue

    item = approval_item
    flash.now[:notice] = l(:notice_successful_update) if !item.approval_issue.closed? && item.update_attributes(approval_item_params)
    @users = @issue.approvers
    @journals = get_journals

    if !@issue.approval_items.where(approved: [false, nil]).any? 
      # Вотчи об утверждении задачи приходят автору, исполнителю, утверждающему и наблюдателям.
      recipients = [@issue.author, @issue.assigned_to] | @issue.watchers.map(&:user)
      if recipients.include?(User.current) && User.current.pref.no_self_notified
        recipients = recipients - [User.current]
      end
      for recipient in recipients.uniq
        Mailer.approved_all(recipient, @issue).deliver
      end
      Mailer.with_deliveries(false) do
        @issue.watchers.where(user_id: @issue.watchers.map(&:user_id)).delete_all
      end

    end    

    respond_to do |format|
      format.html { redirect_to :back }
      format.api {render_api_ok}
      format.js
    end
  end

  def destroy
    find_issue

    flash.now[:notice] = l(:notice_successful_delete) if approval_item.try(:destroy)


    @users = @issue.approvers
    @journals = get_journals

    respond_to do |format|
      format.html { redirect_to :back }
      format.js
      format.api { render_api_ok }
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

    def approval_item
      if params[:id].present?
        item = ApprovalItem.find(params[:id])
      else
        item = @issue.approval_items.where(:user_id => params[:user_id]).first
      end
      item
    end

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
