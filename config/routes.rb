# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :tag_permission_rules, except: :destroy
delete '/tag_permission_rules', controller: 'tag_permission_rules', action: 'destroy'
