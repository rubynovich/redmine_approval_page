if Rails::VERSION::MAJOR >= 3
  RedmineApp::Application.routes.draw do
    resources :approval_items do
      collection do
        get :autocomplete_for_user
      end
    end
  end
else
  ActionController::Routing::Routes.draw do |map|
    map.resources :approval_items
    map.connect   'approval_item/autocomplete_for_user', :controller=> :approval_items, :action => :autocomplete_for_user, :conditions => {:method => :get}
  end
end
