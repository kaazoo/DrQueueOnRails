# take admin rights from user
# call as "script/rails r script/make_noadmin.rb USER"


username = ARGV[0]

if username == nil
  puts "You haven't specified a username as argument."
  puts "Choose one of these:"
  users = User.all()
  users.each do |user|
    puts user.name
  end
else
  puts "Taking admin rights from  user " + username + "."
  user = User.first(:conditions => {:name => username})
  if user != nil
    user.update_attribute :admin, false
    puts "Attribute \"admin\" set to: " + user.admin.to_s
  else
    puts "User " + username + " not found."
  end
end
  
