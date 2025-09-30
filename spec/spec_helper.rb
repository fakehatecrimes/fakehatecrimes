ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)
require 'uri'
require 'rspec/rails'

require 'authlogic'
require "authlogic/test_case"
include Authlogic::TestCase
activate_authlogic

require File.expand_path("../../app/helpers/application_helper", __FILE__)
require File.expand_path("../factories", __FILE__)

RSpec.configure do |config|
  config.before(:each) do
    ActionMailer::Base.deliveries.clear
  end
  
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end

  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = "random"
end

def timed_text_expect( page )
  if Time.now < Date.new(2025, 11, 15) # See application.html.haml
    expect(page).to have_text("Improvements to site - 'Join' sends confimation email, 'Contact' works, 'show password', improved layout, and many others")
  else
    expect(page).to have_text('fake hate crimes: a database of hate crime hoaxes')
  end
end

def middle(record) # Takes an ActiveRecord class as its parameter, eg. User, and returns (roughly) the row from the middle of the table
  records = record.all
  return nil if records.size < 1
  return records[0] if records.size < 3
  n = records.size / 2
  records[n]
end

def logout_user
  get '/logout'
end

def fail_to_login_user(user)
  visit "/login"
  fill_in "user_session_email", :with => user.email
  fill_in "user_session_password", :with => User::INVALID_EMAIL_PASSWORD_OR_SECRET
  click_button "Click here"
end

def login_user(user)
  visit "/login"
  fill_in "user_session_email", :with => user.email
  fill_in "user_session_password", :with => User::VALID_PASSWORD
  click_button "Click here"
end

def go_to_reports_new
  visit '/rules'
  if rand( 2 ) == 0
    check AGREE_TO_RULES_ABOVE
    click_button ADD_FAKE_ABOVE
  else
    check AGREE_TO_RULES_BELOW
    click_button ADD_FAKE_BELOW
  end
end

def fail_to_sign_up_user
  user = FactoryBot.build :user

  visit "/users/new"
  fill_in "user_email", :with => user.email
  fill_in "user_password", :with => User::INVALID_EMAIL_PASSWORD_OR_SECRET
  fill_in "user_password_confirmation", :with => User::INVALID_EMAIL_PASSWORD_OR_SECRET
  fill_in "user_secret_word", :with => WORDS[0]

  click_button HIT_THIS_BUTTON

  user
end

def sign_up_user
   user = FactoryBot.build(:user)
   password = User::VALID_PASSWORD

# --- Sign up ---
   visit "/users/new"
   fill_in "user_email", with: user.email
   fill_in "user_password", with: password
   fill_in "user_password_confirmation", with: password
   fill_in "user_secret_word", with: WORDS[0]
   click_button HIT_THIS_BUTTON

# --- Expect an email was sent ---
   mail = ActionMailer::Base.deliveries.last
   expect(mail.to).to include(user.email)

# --- Extract confirmation link safely ---
   body = mail.multipart? ? mail.text_part.body.to_s : mail.body.to_s
   confirmation_link = URI.extract(body, ["http", "https"]).first
   raise "No confirmation link found!" unless confirmation_link

# --- Visit the confirmation link ---
   visit confirmation_link

# --- Confirm the user without triggering validations ---
   confirmed_user = User.find_by(email: user.email)
   expect(confirmed_user).not_to be_nil

# Use update_columns to skip validations
   confirmed_user.update_columns(
     confirmed_at: Time.current,
     confirmation_token: nil
   )
   confirmed_user.reload
   expect(confirmed_user.confirmed_at).not_to be_nil
   expect(confirmed_user.confirmation_token).to be_nil

# --- Log in ---
   visit "/user_sessions/new"
   fill_in "user_session_email", with: user.email
   fill_in "user_session_password", with: password
   click_button " Click here "  

# Verify login success - you should be on the home page, with the first part of your email displayed
   expect(user.name).not_to be_nil
   expect(page).to have_content( user.name )
   expect(page).to have_content( "Add New Report" )
   user
end

def create_medium_without_report
  m = Medium.count
  f = Fake.count
  visit "/"
  click_on "Media"
  visit "/media/new"
  choose 'article_id_1'
  title = FactoryBot.generate( :word )
  fill_in 'medium[title]', :with => title
  fill_in 'medium[name]', :with => title.shuffle
  fill_in 'medium[authors]', :with => 'Joe Sixpack'
  fill_in 'medium[url]', :with => 'http://' + title.gsub(" ", "") + ".com"
  fill_in 'medium[body]', :with => title.shuffle
  fill_in 'publication_date', :with => '12/02/2525'
  fill_in 'retrieval_date', :with =>   '12/03/2525'
  click_button "Save print or online article, tv or radio program"
  expect(page).to have_text('cannot be in the future')
  fill_in 'publication_date', :with => '12/02/2018'
  fill_in 'retrieval_date', :with =>   '12/03/2018'
  click_button "Save print or online article, tv or radio program"
  expect(page).to have_text("Print or online article, tv or radio program saved")
  expect(page).not_to have_text('cannot be in the future')
  expect(Medium.count).to eq m+1
  expect(Fake.count).to eq f
end

def create_report_with_one_old_and_one_new_medium
  f = Fake.count
  m = Medium.count
  visit "/reports/new"
  if page.body.include?("Check here if you have read the rules below and agree to them")
    check "Check_here_if_you_have_read_the_rules_below_and_agree_to_them"
    click_on "Click here to enter a fake hate crime report"
  end
  type = MediaType.first 
  choose "media_type_id_#{ type.id }"
  middle = Medium.all.last
  Medium.all.reverse.each_with_index do |e, i|
    middle = e if i == MAX_MEDIA / 2 - 1
  end
  check "media_id_#{ middle.id }"                       # Choose old medium
  article = Article.last
  choose "article_id_#{ article.id }"
  title = FactoryBot.generate( :word )
  fill_in 'reason', :with => title.shuffle
  fill_in 'state', :with => 'FL'
  fill_in 'medium[title]', :with => title
  fill_in 'medium[name]', :with => title.shuffle
  fill_in 'medium[body]', :with => title.shuffle         # Add new medium
  fill_in 'medium[authors]', :with => "Joe Bloggs"
  fill_in 'date', :with =>             '12/01/2018'
  fill_in 'publication_date', :with => '12/02/2018'
  fill_in 'retrieval_date', :with =>   '12/03/2018'
  click_button HIT_THIS_BUTTON
  expect(Fake.count).to eq f + 1
  expect(Medium.count).to eq m + 1
  return Fake.last, Medium.last
end

def create_report_of_suspected_hoax_with_no_media
  f = Fake.count
  visit "/reports/new"
  if page.body.include?("Check here if you have read the rules below and agree to them")
    check "Check_here_if_you_have_read_the_rules_below_and_agree_to_them"
    click_on "Click here to enter a fake hate crime report"
  end
  sus = MediaType.all.select{ |mt| mt.name == SUSPECTED }.first
  choose "media_type_id_#{ sus.id }"
  title = FactoryBot.generate( :word )
  fill_in 'reason', :with => title.shuffle
  fill_in 'state', :with => 'FL'
  fill_in 'date', :with => '12/01/2024'
  click_button HIT_THIS_BUTTON
  expect(Fake.count).to eq f + 1
  return Fake.last
end

def create_user_fake_and_medium
  sign_up_user
  create_medium_without_report
  create_report_with_one_old_and_one_new_medium
end
