class ApprovalItemsController < ApplicationController
  unloadable
  before_filter :find_issue, :only => [:new, :create, :destroy, :update, :autocomplete_for_user]

  def new
    @show_form = "true"
    @users = User.active.all(:limit => 100)
    @users -= @issue.approvers

    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace_html 'ajax-modal', :partial => 'approval_items/new'
          page << "showModal('ajax-modal', '400px');"
          page << "$('ajax-modal').addClassName('new-approver');"
        end
      end
    end
  end

  def create
    flash.now[:notice] = l(:notice_successful_create) if User.find(params[:approver][:user_ids]).all? do |user|
      ApprovalItem.create(:approver => user, :approval_issue => @issue)
    end

    @users = @issue.approvers

    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'approval_page', :partial => 'issues/approval_page'
        end
      end
    end
  end

  def update
    item = ApprovalItem.find(params[:id])
    flash.now[:notice] = l(:notice_successful_update) if item.update_attributes(params[:approval_item])

    @users = @issue.approvers

    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'approval_page', :partial => 'issues/approval_page'
        end
      end
    end
  end

  def destroy
    item = ApprovalItem.find(params[:id])

    flash.now[:notice] = l(:notice_successful_delete) if item.destroy

    @users = @issue.approvers

    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'approval_page', :partial => 'issues/approval_page'
        end
      end
    end
  end

  def autocomplete_for_user
    @users = User.active.like(params[:q]).all(:limit => 100)
    @users -= @issue.approvers

    render :layout => false
  end

  private
    def find_issue
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    rescue ActiveRecord::RecordNotFound
      render_404
    end
end
