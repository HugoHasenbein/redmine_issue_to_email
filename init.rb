# encoding: utf-8
#
# Redmine plugin to export an issue as a .eml file
#
# Copyright © 2018 Stephan Wenzel <stephan.wenzel@drwpatent.de>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

require 'redmine'

Redmine::Plugin.register :redmine_issue_to_email do
  name 'Redmine Issue to Email'
  author 'Stephan Wenzel'
  description 'This is a plugin for Redmine to to export an issue as a .eml file'
  version '1.0.1'
  url 'https://github.com/HugoHasenbein/redmine_issue_to_email'
  author_url 'https://github.com/HugoHasenbein/redmine_issue_to_email'

  # link to settings page
  # 0 - apple / thunderbird mix - experimental - code not in this repository
  # 1 - apple mail compatibility
  # 2 - thunderbird compatibility kept identical to outlook in this repository
  # 3 - outlook compatibility - kept identical to thunderbird in this repository
  
  settings  :default => {
                'export_compatibility' => "2",
                'export_user' => "1" # likely admin or first user will always exist
             },
            :partial => 'settings/settings'

  # manage permissions -> Redmine->Administration->Roles and permissions
  project_module :redmine_issue_to_email do

    permission :edit_issue_to_email_settings,
               :issue_to_email_settings => [:edit, :destroy, :update, :test_imap]
   
    permission :store_issue_to_email,
               :issues => [:store, :bulk_store]
  end
    

end

require "redmine_issue_to_email"
