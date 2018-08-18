# redmine_issue_to_email
Plugin for Redmine. With only **one click** bulk export issues to email containing all attachments as email attachments. Email issues look like real issue with clickable attachments.

![PNG that represents a quick overview](/doc/Overview.png)

### Use case(s)

* Save issues to a long term storage IMAP database for documentation purposes
* Add issues to custom software document management systems
* Preserve issues for a time after Redmine
  
[…] 

### Features

* Keeps theme style
* Email issues look like real issues
* Inline all CSS
* Attachments are kept iniline
  * Supports Apple Mail inline attachments style 
  * Supports Thunderbird (also Outlook) inline attachments style
* Keeps all issue attributes and custom field values in email custom headers, so long-term email storage clients can sort by attributes
* Emails get issue ID as email message ID, so email clients relate related issues to each other
* Export permission setting
* Export as seen by selectable user 
* Store to IMAP
  * Save to IMAP folder
  * SSL 
* Store to script
  * Call custom script with following variables 
    * %f - Filename of exported .eml-file
    * %u - Redmine Login
    * %p - Project identifier
    * %s - Issue-subjet (escaped)
    * %id - Issue ID
    * %pid - Project ID
    * %c - Issue created on
    * %a - Issue archived an
* Change issue status on export
* Keep issue detail notice "stored as email"
* Call from context menu
* Bulk export
* Background export (if 'sucker punch' is activated in application.rb)
* Honors workflow permissions
* Honors roles and permisions
  * Edit settings permissions
  * Export permissions
* Inherits settings from parent project unless self defined settings
* Global plugin settings
  
### Install

1. download plugin and copy plugin folder redmine_issue_to_email go to Redmine's plugins folder 

2. go to redmine root folder

`bundle install`

`bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_issue_to_email`

3. optionally add to <Redmine Root>/config/application.rb

`config.active_job.queue_adapter = :sucker_punch` 

4. restart server f.i.  

`sudo /etc/init.d/apache2 restart`

### Uninstall

1. go to redmine root folder

`bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_issue_to_email VERSION=0`

2. go to plugins folder, delete plugin folder redmine_issue_to_email

`rm -r redmine_issue_to_email`

3. delete from <Redmine Root>/config/application.rb

`config.active_job.queue_adapter = :sucker_punch` 

4. restart server f.i.  

`sudo /etc/init.d/apache2 restart`

### Use

* Make sure you have the right permission to "Manage Issue To Email Settings" in the roles and permission settings in the Redmine Administration menu

* Go to Administration -> Settings -> API
  * Choose Enable REST web service
 
* Go to Administration -> Plugins -> Redmine Issue To Email -> Configure
  * Select Apple- or Thunderbird-compatibilty (important - both email clients behave differently)
  * Select from which user's view the issue should be exported
 
* Go to Projects -> Settings -> Modules and add Issue-To-Email to project

* Go to Projects -> Settings -> Issue-To-Email
  * Optionally enter IMAP credentials
  * Optionally enter server script with available variables (in Help)
  * Optionallly choose status after export

**Save!**

Now you can right click an issue or on many issues at a time in the issue index view export your issues. Issues will be saved to the destination configured in it's project.

**Have fun!**

### Localisations

* English
* German

### Change-Log

* **1.0.1** 
  * added security measures against unauthorized access
  * added redirect to login for unauthorized access
  * corrected typos in localization strings
  * added conversion of attachment urls next to present conversion of attachment paths
  * added feature to allow for empty host string in global Redmine settings
  
* **1.0.0** running on Redmine 3.4.6