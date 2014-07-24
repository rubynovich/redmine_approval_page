if Rails::VERSION::MAJOR >= 3
  RedmineApp::Application.routes.draw do
    resources :approval_items do
      collection do
        get :autocomplete_for_user
        get :card
      end
    end
    post '/issues/:issue_id/approvers' => 'approval_items#create'
    delete '/issues/:issue_id/approvers/:user_id' => 'approval_items#destroy'
    put '/issues/:issue_id/approvers/:user_id' => 'approval_items#update'
  end
else
  ActionController::Routing::Routes.draw do |map|
    map.resources :approval_items
    map.connect   'approval_item/autocomplete_for_user', :controller=> :approval_items, :action => :autocomplete_for_user, :conditions => {:method => :get}
    map.connect   'approval_item/card', :controller=> :approval_items, :action => :card, :conditions => {:method => :get}
  end
end
