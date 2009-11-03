Factory.define :user do |f|
  f.sequence(:login) {|n| "defaultlogin#{n}" } 
  f.password "secret"
  f.password_confirmation {|u| u.password }
end
