require "spec_helper"

RSpec.feature "Sign up", :type => :feature do

  before do
    fake, medium = create_user_fake_and_medium
    expect(fake.media.size).to eq 2
    expect(medium.fakes.size).to eq 1
  end

  scenario 'User visits sign up page' do
    visit '/logout'
    click_on 'Join'
    expect(page).to have_text('Login')
    expect(page).not_to have_text('Logout')
    expect(page).to have_text('Enter the letters and numbers in the picture (case insensitive)')
  end

  scenario "User fails to sign up" do
    visit "/logout"
    fail_to_sign_up_user
    expect(page).to have_text("Login")
    expect(page).not_to have_text("Logout")
    expect(page).to have_text( 'fakehatecrimes.org password is too short (minimum is 8 characters)' )
  end

  scenario 'User visits home page' do
    visit '/'
    expect(page).to have_text('Reports')
    expect(page).to have_text('Search')
    expect(page).to have_text('Media')
    expect(page).to have_text('Graphs')
    expect(page).to have_text('Contact')
    expect(page).to have_text('Help')
    expect(page).to have_text('Logout')
    expect(page).not_to have_text('Login')
    timed_text_expect(page)
  end

  scenario 'User visits reports page' do
    visit '/'
    click_on 'Reports'
    expect(page).not_to have_text('Login')
    expect(page).to have_text('Logout')
    timed_text_expect(page)
  end

  scenario 'User visits search page' do
    visit '/'
    click_on 'Search'
    expect(page).not_to have_text('Login')
    expect(page).to have_text('Logout')
    expect(page).to have_text('Enter text to search for.')
    click_on 'Then click here'
    expect(page).to have_text('Enter text to search for.')
  end

  scenario 'User visits media page' do
    visit '/'
    click_on 'Media'
    expect(page).not_to have_text('Login')
    expect(page).to have_text('Logout')
    expect(page).to have_text('New print or online article, tv or radio program')
  end

  scenario 'User visits graphs page' do
    visit '/'
    click_on 'Graphs'
    expect(page).not_to have_text('Login')
    expect(page).to have_text('Logout')
    expect(page).to have_text('These graphs chart reports of fake hate crimes over time.')
  end

  scenario 'User visits change password page' do
    visit '/'
    click_on 'Help'
    expect(page).not_to have_text('Login')
    expect(page).to have_text('Logout')
    expect(page).to have_text('Old password')
    expect(page).to have_text('Password')
  end

  scenario 'User visits contact page' do
    visit '/'
    click_on 'Contact'
    expect(page).not_to have_text('Login')
    expect(page).to have_text('Logout')
    expect(page).to have_text('Send message to fakehatecrimes.org')
  end

  scenario "User creates 'suspected' report with no media" do
    m = Medium.count
    f = Fake.count
    visit "/reports/new"
    expect(page).not_to have_text('Report saved')
    mts = MediaType.all
    expect(mts.size > 0).to be true
    type = MediaType.all.select{ |mt| mt.name == SUSPECTED }.first
    choose "media_type_id_#{ type.id }"
    middle = nil
    Medium.all.reverse.each_with_index do |e, i|
      middle = e if i == MAX_MEDIA / 2 - 1
    end
    check "media_id_#{ middle.id }"
    article = Article.last
    choose "article_id_#{ article.id }"
    title = FactoryBot.generate( :word )
    fill_in 'reason', :with => title.shuffle
    fill_in 'state', :with => 'NY'
    fill_in 'city', :with => 'New York'
    fill_in 'date', :with => '12/01/2525'
    click_button HIT_THIS_BUTTON
    expect(page).to have_text('cannot be in the future')
    fill_in 'date', :with => '12/01/2018'
    click_button HIT_THIS_BUTTON
    expect(page).to have_text('Report saved')
    expect(page).not_to have_text('cannot be in the future')
    expect(Medium.count).to eq m
    expect(Fake.count).to eq f+1
  end

  scenario "User fails to create report without medium" do
    m = Medium.count
    f = Fake.count
    visit "/reports/new"
    type = MediaType.all.select{ |mt| mt.name != SUSPECTED }.last
    choose "media_type_id_#{ type.id }"
    article = Article.last
    choose "article_id_#{ article.id }"
    title = FactoryBot.generate( :word )
    fill_in 'reason', :with => title.shuffle
    fill_in 'state', :with => 'NY'
    fill_in 'city', :with => 'New York'
    fill_in 'date', :with => '12/01/2018'
    click_button HIT_THIS_BUTTON
    expect(page).not_to have_text('Report saved')
    expect(Medium.count).to eq m
    expect(Fake.count).to eq f
  end

  scenario "User tries to change report from 'suspected' with no medium" do
    fake = create_report_of_suspected_hoax_with_no_media
    expect( fake.media.empty? ).to be true
    expect( fake.media_type.name ).to eq SUSPECTED

    visit '/'
    expect(page).to have_text('Logout')
    expect(body.include?("id=report_#{fake.id}_")).to be true
    click_link "report_#{fake.id}_"
    title = FactoryBot.generate( :word )
    fill_in 'fake_reason', :with => title
    type = MediaType.all.select{ |mt| mt.name != SUSPECTED }.first
    choose "media_type_#{ type.id }"
    click_button HIT_THIS_BUTTON
    expect(page).to have_text("Report not saved")
  end

  scenario "User changes report with a medium" do
    fake, medium = create_report_with_one_old_and_one_new_medium
    visit '/'
    expect(page).to have_text('Logout')
    expect(body.include?("id=report_#{fake.id}_")).to be true
    click_link "report_#{fake.id}_"
    title = FactoryBot.generate( :word )
    fill_in 'fake_reason', :with => title
    type = MediaType.all.select{ |mt| mt.name == SUSPECTED }.first
    choose "media_type_#{ type.id }"
    click_button HIT_THIS_BUTTON
    expect(page).to have_text(title)
    expect(page).to have_text('Report saved')
  end

  scenario "User changes medium" do
    medium = Medium.all.last
    visit "/media"
    expect(page).to have_text('Logout')
    expect(body.include?("id=medium_#{medium.id}_")).to be true
    click_link "medium_#{medium.id}_"
    title = FactoryBot.generate( :word )
    expect(page).not_to have_text("Updated")
    expect(page).not_to have_text(title)
    fill_in 'medium_title', :with => title
    click_button 'Save'
    expect(page).to have_text("Updated")
    expect(page).to have_text(title)
  end

  scenario "User creates invalid report with valid medium, and medium saves" do
    m = Medium.count
    f = Fake.count
    visit "/reports/new"
    article = Article.last
    choose "article_id_#{ article.id }"
    title = FactoryBot.generate( :word ) + ' ' + FactoryBot.generate( :word ).upcase
    fill_in 'medium_title', :with => title
    fill_in 'medium_name', :with => title.shuffle
    fill_in 'medium_body', :with => title.shuffle
    fill_in 'medium_authors', :with => "Joe Bloggs"
    fill_in 'date', :with =>             '12/01/2012'
    fill_in 'publication_date', :with => '12/02/2012'
    fill_in 'retrieval_date', :with =>   '12/03/2012'
    click_button HIT_THIS_BUTTON
    expect(Medium.count).to eq 1 + m
    expect(Fake.count).to eq f
  end

end
