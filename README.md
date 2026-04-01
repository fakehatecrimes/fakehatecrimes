## fakehatecrimes

This is a project to create a database of hate crime hoaxes. It builds on the work of Laird Wilcox, whose 'Crying Wolf' is the only book dedicated to this subject so far. It is hosted at [fakehatecrimes.org](http://fakehatecrimes.org).

### Running in Docker (recommended for Mac M-series and other non-Linux platforms)

The app runs on Ruby 2.3.8 / Rails 4.2 / MariaDB 10.1. On modern hardware the easiest path is Docker.

**First-time setup:**

```
./docker-setup.sh
./docker-db-import.sh
```

**Start the app:**

```
./docker-start.sh
```

This drops you into a shell inside the web container. Start the server:

```
./docker-rails-3003.sh
```

or manually:

```
rails server -b 0.0.0.0 -p 3003
```

The app is then available at [http://localhost:3003/](http://localhost:3003/).

**Set the administrator password** (first time only). In a second terminal, open a shell in the running container:

```
docker-compose exec web bash
```

Then in the Rails console:

```
rails console
user = User.first
user.password = "Helloworld42"
user.password_confirmation = "Helloworld42"
user.secret_word = "xyzabc"
user.save!
```

### CAPTCHA / secret word

The registration form shows a CAPTCHA image and asks you to type what you see.

- **In development and test** the answer is always `xyzabc` regardless of what the image shows.
- **In production** the real CAPTCHA images (stored in `tmp/words/`, not committed to git) are copied to `public/images/` on the server. The accepted words are the 16 words shown in those images (case-insensitive). Anyone reading this repo on GitHub only sees placeholder images and cannot determine the valid words.

The images are named `word0.jpg` – `wordF.jpg` (hexadecimal), and one is chosen at random each time the registration page loads.

### Confirmation email

After registering, users receive a confirmation email and must click the link before they can log in. In development, email is not delivered; instead look in `log/development.log` for a line like:

```
UserMailer: confirmation_email: @url http://localhost:3003/users/confirm?token=ABC123
```

Visit that URL directly in your browser to confirm the account.

Users who registered before the email-confirmation feature was added (i.e. who have no confirmation token and no confirmed date) are treated as already confirmed and can log in normally.

Log in as the new user and carry out the following tests:

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











