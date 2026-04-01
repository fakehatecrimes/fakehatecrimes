Fakehatecrimes::Application.routes.draw do

  get 'search' => 'media#search', as: :search

  resources :fakes, :media, :user_sessions, :password_resets, :emailers, :searches 
  resources :users do
    get :confirm, on: :collection
  end
  
  root :to =>                'fakes#index'

  get  'rules'       =>      'main#rules'
  get  'lairdwilcox' =>      'main#lairdwilcox'
  get  'graphs' =>           'graphs#index'

  get  'media' =>            'media#index'
  get  'medium/new' =>       'media#new'
  get  'media/:id/edit' =>   'media#edit'
  get  'media/:id/pic' =>    'media#pic'
  post 'medium/create' =>    'media#create'

  patch 'reports' =>         'fakes#index'
  put  'reports' =>          'fakes#index'
  get  'reports' =>          'fakes#index'
  get  'reports/index' =>    'fakes#index'
  post 'reports' =>          'fakes#index'
  post 'reports/index' =>    'fakes#index'
  post 'reports/create' =>   'fakes#create'
  get  'reports/new' =>      'fakes#new'
  post 'reports/new' =>      'fakes#new'
  get  'reports/:id' =>      'fakes#show'
  get  'reports/:id/edit' => 'fakes#edit'

  get 'login' =>  'user_sessions#new',     :as => :login,  via: [:get, :post]
  get 'logout' => 'user_sessions#destroy', :as => :logout, via: [:get, :post]

  post 'password_resets/new' => "password_resets#new"
   put 'password_resets/new' => "password_resets#new"
  post 'sendmail'            => "emailers#sendmail"
   get 'email'               => "emailers#index"

  delete 'users/delete' =>   "users#destroy"
    post 'users/delete' =>   "users#destroy"

end
