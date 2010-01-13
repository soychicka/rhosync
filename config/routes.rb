ActionController::Routing::Routes.draw do |map|
  map.resources :clients
  map.resources :iphones, :controller => 'clients'
  map.resources :blackberrys, :controller => 'clients'
  map.resources :androids, :controller => 'clients'
  map.resources :winces, :controller => 'clients'

  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.register '/register', :controller => 'users', :action => 'create'
  map.signup '/signup', :controller => 'users', :action => 'new'

  # more for routes
  map.forgot_password '/forgot_password', :controller => 'users', :action => 'forgot_password'
  map.reset_password '/reset_password', :controller => 'users', :action => 'reset_password'

  map.resources :users
  map.resource :session

  # 1.2-style routes
  map.connect 'apps/:app_id/sources/client_login', :controller => 'sessions', :action => 'client_login'
  map.connect 'apps/:app_id/subscribe', :controller => 'apps', :action => 'subscribe'

  # Pre 1.2-style routes
  map.connect 'apps/:app_id/sources/:id/client_login', :controller => 'sessions', :action => 'client_login'

  src_collection = { :clientcreate => :get,
                     :clientregister => :post,
                     :clientreset => :get }

  src_member = { :createobjects => :post,
                 :updateobjects => :post,
                 :deleteobjects => :post,
                 :search => [:get, :post],
                 :ask => :post,
                 :ping => :get,
                 :ping_user => :get,
                 :refresh => :get,
                 :clientcreate => :get,
                 :clientreset => :get }

  map.resources :sources, :collection => src_collection, :member => src_member

  map.resources :apps do |app|
    app.resources :sources, :collection => src_collection, :member => src_member
  end

  # The priority is based upon order of creation: first created -> highest priority.


  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => "apps"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  map.connect '*path' , :controller => 'sessions' , :action => 'unrecognized?'
end
