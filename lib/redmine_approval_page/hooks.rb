module RedmineApprovalPage
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_sidebar_planning_bottom,
              :partial => 'issues/approval_page'
  end
end 
