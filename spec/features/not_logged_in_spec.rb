require 'spec_helper'

RSpec.feature 'Front page', type: :feature do

  before do
    create_user_fake_and_medium
    visit "/logout"
  end

  scenario 'User visits home page' do
    visit '/'
    expect(page).to have_text('Log in')
    expect(page).not_to have_text('Log out')
    expect(page).to have_text('fake hate crimes: a database of hate crime hoaxes in the usa')
    expect(page).to have_text 'committed (mostly) in the USA'
  end

  scenario 'User visits reports page' do
    visit '/'
    click_on 'Reports'
    expect(page).to have_text('Log in')
    expect(page).not_to have_text('Log out')
    expect(page).to have_text('fake hate crimes: a database of hate crime hoaxes in the usa')
  end

  scenario 'User visits sign up page' do
    visit '/'
    click_on 'Join'
    expect(page).to have_text('Log in')
    expect(page).not_to have_text('Log out')
    expect(page).to have_text('Enter the letters and numbers in the picture (case insensitive)')
  end

  scenario 'User visits login page' do
    visit '/'
    click_on 'Log in'
    expect(page).to have_text('Log in')
    expect(page).not_to have_text('Log out')
  end

  scenario 'User visits search page' do
    visit '/'
    click_on 'Search'
    expect(page).to have_text('Log in')
    expect(page).not_to have_text('Log out')
    expect(page).to have_text('Enter text to search for.')
  end

  scenario 'User visits media page' do
    visit '/'
    click_on 'Media'
    expect(page).to have_text('Log in')
    expect(page).not_to have_text('Log out')
    expect(page).to have_text('New print or online article, tv or radio program')
  end

  scenario 'User visits graphs page' do
    visit '/'

    click_on 'Graphs'
    expect(page).to have_text('Log in')
    expect(page).not_to have_text('Log out')
    expect(page).to have_text('These graphs chart reports of fake hate crimes over time.')
  end

  scenario 'User visits forgot password page' do
    visit '/'
    click_on 'Help'
    expect(page).to have_text('Log in')
    expect(page).not_to have_text('Log out')
    expect(page).to have_text('Enter the e-mail address with which you joined this site, and instructions to reset your password will be emailed to you')
    fill_in 'email', with: EMAIL_ADDRESS
    click_on 'Reset my password'
    expect(page).to have_text('No user was found with that email address')
  end

  scenario 'User visits contact page' do
    visit '/'
    click_on 'Contact'
    expect(page).to have_text('Log in')
    expect(page).not_to have_text('Log out')
    expect(page).to have_text('Send message to fakehatecrimes.org')
    fill_in 'recipient', with: EMAIL_ADDRESS
    fill_in 'subject', with: 'A message'
    fill_in 'message', with: 'Hello'
    fill_in 'secret_word', with: 'cheese'
    click_on 'Send email'
#    expect(page).to_have_text 'Message sent'
  end
end
