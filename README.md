# redmine_issue_to_email
Plugin for Redmine. With only **one click** bulk export issues to email containing all attachments as email attachments.

### Use case(s)

* Save issues to a long term storage IMAP database for documentation purposes
* Add issues to custom software document management systems
* Presreve issues for a time after Redmine
  
[…] 

### Features

* Keeps Theme Style
* Email issues look like real issues
* Inline all CSS
* Attachments are kept iniline
 - Supports Apple Mail inline attachments style 
 - Supports Thunderbird (also Outlook) inline attachments style
* Export permission setting
* Export as seen by selectable user 
* Store to IMAP
 - Save to IMAP folder
 - SSL 
* Store to script
 - Call custom script with following variables 
 - %f - Filename of exported .eml-file
 - %u - Redmine Login
 - %p - Project identifier
 - %s - Issue-subjet (escaped)
 - %id - Issue ID
 - %pid - Project ID
 - %c - Issue crrated on
 - %a - Issue archived an
* Change issue status on export
* Keep issue detail notice "stored as email"
* Call from context menu
* Bulk export
* Background exportt (if sucker punch is activated in application.rb)
* Honors workflow permissions
* Honors roles and permisions
 - Edit settings permissions
 - Export permissions
* Inherits settings from parent project unless self defined settings
* Global plugin settings
  
### Install

1. go to plugins folder

`git clone https://github.com/HugoHasenbein/redmine_issue_to_email.git`

2. go to redmine root folder

`bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_issue_to_email`

3. Optionally add

`config.active_job.queue_adapter = :sucker_punch` 

to <Redmine Root>/config/application.rb

4. restart server f.i.  `sudo /etc/init.s/apache2 restart`

### Uninstall

1. go to redmine root folder

`bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_issue_to_email VERSION=0`

2. go to plugins folder

`rm -r redmine_issue_to_email`

3. delete 

`config.active_job.queue_adapter = :sucker_punch` 

from <Redmine Root>/config/application.rb

3. restart server f.i.  `sudo /etc/init.s/apache2 restart`

### Use

* Make sure you have the right permission to "Manage Issue To Email Settings" in the roles and permission settings in the Redmine Administration menu

* Go to Administration -> Settings -> API
 - Choose Enable REST web service
 
* Go to Administration -> Plugins -> Redmine Issue To Email -> Configure
 - Select Apple- or Thunderbird-compatibilty
 - Select from which user's view the issue should be exported
 
* Go to Projects -> Settings -> Modules and add Issue-To-Email to project

* Go to Projects -> Settings -> Issue-To-Email
  - Optionally enter IMAP credentials
  - Optionally enter server script with available variables (in Help)
  - Optionallly choose status after export

**Save!**

Now you can right click an issue or on many issues at a time in the issue index view export your issues. Issues will be saved to the destination configured in it's project.

**Have fun!**

### Localisations

* English
* German

### Change-Log

* **1.0.0** running on Redmine 3.4.6
