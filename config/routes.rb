DrQueueOnRails::Application.routes.draw do

  devise_for :users

  root :to => 'main#index'
  resources :main, :only => :index
  match 'main/computers' => 'main#computers'
  match 'main/users' => 'main#users'
  match 'main/update_user' => 'main#update_user'

  resources :jobs
  match 'jobs/:id/view_log' => 'jobs#view_log'
  match 'jobs/:id/view_image' => 'jobs#view_image'
  match 'jobs/:id/load_image' => 'jobs#load_image'
  match 'jobs/:id/rerun' => 'jobs#rerun'
  match 'jobs/:id/download' => 'jobs#download'
  match 'jobs/:id/stop' => 'jobs#stop'
  match 'jobs/:id/hstop' => 'jobs#hstop'

  resources :rendersessions
  match 'rendersessions/set_active' => 'rendersessions#set_active'
  match 'rendersessions/calculate_costs_text' => 'rendersessions#calculate_costs_text'

  match 'payments/checkout' => 'payments#checkout'
  match 'payments/confirm' => 'payments#confirm'
  match 'payments/complete' => 'payments#complete'
  match 'payments/error' => 'payments#error'

  match 'accept_tos' => 'application#accept_tos'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  #root :to => 'main#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
