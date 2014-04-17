require 'redmine'
require 'redmine_approval_page/hooks'

Redmine::Plugin.register :redmine_approval_page do
  name 'Approval Page'
  author 'Roman Shipiev'
  description 'Approval Page for Redmine'
  version '0.0.1'
  url 'https://bitbucket.org/rubynovich/redmine_approval_page'
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

Rails.configuration.to_prepare do

  [
   :issue, 
   :user,
   :mailer,
   :journal,
   :watcher,
   :issues_helper
  ].each do |cl|
    require "approval_page_#{cl}_patch"
  end

  [
    [Issue, ApprovalPagePlugin::IssuePatch],
    [User,  ApprovalPagePlugin::UserPatch],
    [Mailer, ApprovalPagePlugin::MailerPatch],
    [Journal, ApprovalPagePlugin::JournalPatch],
    [Watcher, ApprovalPagePlugin::WatcherPatch],
    [IssuesHelper, ApprovalPagePlugin::IssuesHelperPatch]
  ].each do |cl, patch|
    cl.send(:include, patch) unless cl.included_modules.include? patch
  end



end
