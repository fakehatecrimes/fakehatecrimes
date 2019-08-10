%w[calendar_date_select includes_helper].each { |file| 
# Changed by me from the original code in vendor/plugins/ to look in lib/ which is where Rails 3 told me to stick it
  require File.join( Rails.root, "lib", "calendar_date_select", "lib", file ) 
}

ActionView::Helpers::FormHelper.send(:include, CalendarDateSelect::FormHelper)
ActionView::Base.send(:include, CalendarDateSelect::FormHelper)
ActionView::Base.send(:include, CalendarDateSelect::IncludesHelper)

# install files
# useful comment
# app/assets/javascripts/calendar_date_select/public/javascripts/calendar_date_select/calendar_date_select.js
# More changes by me, based on having to move all the code around, both Ruby and Javascript, to work with Rails 3
APP_ASS_CAL = 'app/assets/javascripts/calendar_date_select'
CAL_APP_SRC = "#{Rails.root}" + '/' + APP_ASS_CAL + '/public/javascripts/calendar_date_select/calendar_date_select.js'
unless File.exists?( CAL_APP_SRC )

# This shouldn't happen - it's trying to install the code at load time - I should already have installed it
  raise "Calendar Javascript is not installed - it should be " + CAL_APP_SRC 

  [ APP_ASS_CAL + '/public', 
    APP_ASS_CAL + '/public/javascripts/calendar_date_select',
    APP_ASS_CAL + '/public/stylesheets/calendar_date_select', 
    APP_ASS_CAL + '/public/images/calendar_date_select', 
    APP_ASS_CAL + '/public/javascripts/calendar_date_select/locale'].each do |dir|

    source = File.join(directory,dir)
    dest = Rails.root + dir
    FileUtils.mkdir_p(dest)
    FileUtils.cp(Dir.glob(source+'/*.*'), dest)
  end
end

