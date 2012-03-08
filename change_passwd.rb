
### run this script using runner
require 'optparse'
require 'readline'
require 'pp'
# require 'rubygems'
# require 'highline/import'
#require 'ruport'
#require 'redmine'
def to_bool(str = '')
  return true if str == true || str =~ (/(true|t|yes|y|1)$/i)
  return false if str == false || str.blank? || str =~ (/(false|f|no|n|0)$/i)
  raise ArgumentError.new("invalid value for Boolean: \"#{str}\"")
end
###
def list_users
  puts "%4s %-20s %-20s %-20s" % %w(ID LOGIN FIRST_NAME LAST_NAME)
  puts "-" * 64
  User.all.sort! do |a,b|
    a.id <=> b.id
  end.each do |user|
    puts "%4d %-20s %-20s %-20s" % [user.id ,user.login, user.firstname, user.lastname]
  end
end
# CREATE TABLE "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, "login" varchar(30) DEFAULT '' NOT NULL, "hashed_password" varchar(40) DEFAULT '' NOT NULL, "firstname" varchar(30) DEFAULT '' NOT NULL, "lastname" varchar(30) DEFAULT '' NOT NULL, "mail" varchar(60) DEFAULT '' NOT NULL, "admin" boolean DEFAULT 'f' NOT NULL, "status" integer DEFAULT 1 NOT NULL, "last_login_on" datetime, "language" varchar(5) DEFAULT '', "auth_source_id" integer, "created_on" datetime, "updated_on" datetime, "type" varchar(255), "identity_url" varchar(255), "mail_notification" varchar(255) DEFAULT '' NOT NULL, "salt" varchar(64));
def readPassword
  ### works only under linux ,but other options include third party
  ### gems which is overkill .
  print "Password >"
  system "stty -echo"
  password = gets.chomp
  system "stty echo"
  print "\nRetype Password >"
  system "stty -echo"
  retype_password = gets.chomp
  system "stty echo"
  print "\n"
  res= {
    :success => (retype_password == password) ,
    :password => password
  }
  return res
end

def add_user
  stty_save = `stty -g`.chomp
  begin
    login = Readline.readline('login > ', true)
    first_name = Readline.readline('First Name > ', true)
    last_name = Readline.readline('Last Name > ', true)
    mail = Readline.readline('mail > ', true)
    admin = Readline.readline('admin > ', true)
    # password = Readline.readline('admin > ', true)
    
    oUser=User.new(:firstname => first_name,
                   :lastname  => last_name,
                   :mail  => mail)
    ### The login & admin are attr_protected
    oUser.login = login
    oUser.admin = to_bool(admin)
    hPassword=readPassword
    while !hPassword[:success]
      puts "Error in password typing"
      hPassword=readPassword
    end
    oUser.password = hPassword[:password]
    # pp oUser
    # exit
    if !oUser.save
      pp oUser.errors
    end
  rescue Interrupt => e
    system('stty', stty_save) # Restore
    exit
  end
end
def remove_user(id = nil)
  return if id.nil?
  oUser=User.find_by_id(id)
  oUser.delete if !oUser.nil?
end

def change_password(id = nil)
  return if id.nil?
  oUser=User.find_by_id(id)
  oPassword=readPassword
  while !oPassword[:success]
    puts "Error in password typing"
    oPassword=readPassword
  end
  oUser.password = oPassword[:password]
  begin 
    oUser.save!
  rescue Exception => e
    puts "Error saving new password",e.message
  end
end 
options = {} 

optparse = OptionParser.new do |opts|                 
  opts.on "-l","--list","List the exisitng redmine users " do
    list_users
  end
  opts.on "-a","--add","Add a new user (interactive mode) " do
    add_user
  end
  opts.on "-d","--delete","=MANDATORY","Add a new user (interactive  mode) " do |duser|
    remove_user duser
  end
  opts.on "-p","--password","=MANDATORY","Change user password  " do |duser|
    change_password duser
  end
  # opts.on "-u" ,"--user","=MANDATORY","The username to set password for" do
  #   options[:user]=true
  # end
  # opts.on "-p" ,"--password","=MANDATORY","The password to set" do
  #   options[:password]=true
  # end
end
# puts options[:user].nil?
# abort
# exit
begin
  optparse.parse!
  # if options[:user].nil? != options[:password].nil?
  #   raise new Exception
  # end
rescue 
  puts $!
  puts optparse
end

