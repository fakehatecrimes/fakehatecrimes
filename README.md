## fakehatecrimes

This is a project to create a database of hate crime hoaxes. It builds on the work of Laird Wilcox, whose 'Crying Wolf' is the only book dedicated to this subject so far. It is hosted at [fakehatecrimes.org](http://fakehatecrimes.org).

You will need to run `bundle install`

If you cannot install Bundler 1.17.3 on your computer, you will need to run it in [Docker](https://www.docker.com), using 

`docker-setup.sh ; docker-start.sh`

To initialize the database, log into the MySQL command program as root

`$ mysql -u root -p`

then

`create database fakehatecrimesdevelopment;`
`use fakehatecrimesdevelopment;`

`GRANT ALL PRIVILEGES ON fakehatecrimesdevelopment TO 'root'@'localhost';`
`GRANT ALL PRIVILEGES ON fakehatecrimesdevelopment.* TO 'root'@'localhost';`

and

`source ./db/database.sql.txt`

Then do the same with database `fakehatecrimestest`

If you are using Docker, you have to run

`docker-db-import.sh ; docker-db-shell.sh`

You need to do this before running the tests: `rake spec`

You will then need to save a password for the administrator. Do this using `rails console` 

`user=User.first ; user.password="Helloworld42" ; user.password_confirmation="Helloworld42" ; user.secret_word="cheese" ; user.save!`

You can now run `rails server`

Note that whenever you have to fill in a captcha word in development, you should always enter 'cheese'

Visit [http://localhost:3000/](http://localhost:3000/), click on 'Join', and fill in the form. 

Look in log/development.log for something like this: http://fakehatecrimes.org/users/confirm?token=ABC123

Go to [http://localhost:3000/users/confirm?token=ABC123](http://localhost:3000/users/confirm?token=ABC123)

Log in as the new user, and carry out the following tests:

Click on 'Add New Report'

Click 'Check here if you have read the rules below and agree to them', and click "Click here to enter a fake hate crime report"

Leave radio button 'suspected' selected. Enter Date of hoax, City, State, and Reason, and click 'Fill in the form and hit this button' at the bottom.

You should see the message 'Report saved'

Now click 'Add New Report' again

Follow the steps above, but choose something other than 'suspected' from 'What type of fake hate crime?'

When you hit 'Fill in the form and hit this button', you should see message 'Report not saved' at the top

Keep the 'What type of fake hate crime?' radio button something other than 'suspected', and this time, fill in the 'Add New Article or Program' form at the bottom

Try various invalid entries, such as making 'The day you read the article' before 'Approximate date of hoax' at the top, or before 'The day the article was first published' at the bottom

Each time you enter invalid data, and hit 'Fill in the form and hit this button', you should see 'Report not saved' at the top

Enter valid data (URL can be any valid web address, e.g. https://translate.google.com/), and hit 'Fill in the form and hit this button'

This time, you should go to the home page, with the message 'Report saved', and a list of reports, your new one at the top

Click on your new report. Click on the checkbox directly under 'ARTICLES/PROGRAMS', next to the medium you just entered, disconnecting that medium from this report.

Hit 'Fill in the form and hit this button'. You should see 'Report not saved: a report must have at least one tv, radio, print or online reference unless it's merely 'suspected' at the top.

Change 'WHAT TYPE OF FAKE HATE CRIME' back to 'suspected', and try to save it again. This time, it should save.

Now go back to the report, check on one or more from the list of 'ARTICLES/PROGRAMS', and save again.

Now click on 'Media' at the top, and 'New print or online article, tv or radio program' underneath, to the left.

Fill in an invalid medium. Make sure it gives an error message at the top, and remains on the same page, when you click '"Save print or online article, tv or radio program".

Now make it valid. Put the words 'THIS IS A HOAX' in 'Summary of content'. Click the button, and it should say "Print or online article, tv or radio program saved" at the top, and show a list of media

Click on 'Reports' at the top. Choose the report you recently created - at the top of the list of reports, in the first column. 

Enter 'THIS IS A HOAX' in 'Summary'. From the list of 'ARTICLES/PROGRAMS', choose the one you just created, and click 'Fill in the form and hit this button'. 

Choose that report again, and it should show that you have associated the report with the new medium you just created. Click on the link to the name of that medium, under 'ARTICLES/PROGRAMS', and it should show the name of the report at the top, under 'reports'. 

Click on 'Search' at the top. Enter 'this is a hoax' in lower case letters, and click on 'Then click here'. You should see your recently created report and medium listed below. 











