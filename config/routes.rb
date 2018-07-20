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

RedmineApp::Application.routes.draw do
  
  # issue to email settings creation and administration
  resources :projects do #project
    member do #project_names
      scope 'settings' do #only for settings
        resources :issue_to_email_settings, :param => :issue_to_email_setting_id #all necessary routes
      end
    end
  end
  
  match "issue_to_email_test_imap" => "issue_to_email_settings#test_imap", :as => "issue_to_email_test_imap", :via => [:post, :put]
  
  match "issues/:id/store" => "issues#store", :as => "issue_to_email_store", :via => [:get]
  match "issues/store"     => "issues#bulk_store", :as => "issue_to_email_bulk_store", :via => [:post]
  
end
