require 'redmine'
require 'redmine_approval_page/hooks'

Redmine::Plugin.register :redmine_approval_page do
  name 'Redmine Approval Page plugin'
  author 'Roman Shipiev'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'https://github.com/rubynovich/redmine_approval_page'
  author_url 'http://roman.shipiev.me'

  project_module :approval_page do
    permission :view_approval_items, {:approval_items => [:index, :show]}, :require => :loggedin
    permission :manage_approval_items, {:approval_items => [:new, :create, :edit, :update, :destroy]}, :require => :loggedin
  end

#  menu :project_menu, :approval_page,
#    {:controller => :approval_items, :action => :index},
#    :param => :project_id,
#    :caption => :label_approval_page,
#    :if => Proc.new{ User.current.allowed_to?({:controller => :approval_issues, :action => :index}, nil, {:global => true}) }

  settings :default => {
                         :issue_status => IssueStatus.first(:conditions => {:is_closed => true}).id
                       },
           :partial => 'settings/settings'
end

if Rails::VERSION::MAJOR < 3
  require 'dispatcher'
  object_to_prepare = Dispatcher
else
  object_to_prepare = Rails.configuration
end

object_to_prepare.to_prepare do
  [:issue, :user].each do |cl|
    require "approval_page_#{cl}_patch"
  end

  [
    [Issue, ApprovalPagePlugin::IssuePatch],
    [User,  ApprovalPagePlugin::UserPatch]
  ].each do |cl, patch|
    cl.send(:include, patch) unless cl.included_modules.include? patch
  end
end
