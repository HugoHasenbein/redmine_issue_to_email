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

module RedmineIssueToEmail
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method_chain :project_settings_tabs, :issue_to_email_settings
        end
      end


      module InstanceMethods
        # Append tab for issue templates to project settings tabs.
        def project_settings_tabs_with_issue_to_email_settings
          tabs = project_settings_tabs_without_issue_to_email_settings
                     
          # we will get all calls through this interface
          # therefore, check routing resources get/post - new/create/edit/update/destroy 
          # for dispatching to the right controller action
          action = {  name:         'issue_to_email_settings',
                      partial:      'projects/settings/issue_to_email/edit',
                      controller:   'issue_to_email_settings', #needed only for permission checking
                      action:       :edit,                     #needed only for permission checking
                      label:        :label_issue_to_email_settings_plural }
    
          if request.get? 
            # was index or show request => react with edit
            @issue_to_email_setting = IssueToEmailSetting.find_or_new(@project.id)
            if @issue_to_email_setting.new_record?
              @issue_to_email_setting.project_id = @project.id
              @issue_to_email_setting.save 
            end
            params[:issue_to_email_setting_id] = @issue_to_email_setting.id
            tabs << action if User.current.allowed_to?(action, @project)
      
          elsif params[:better_issue_setting_id].present? && request.put?
            # was update request 
            tabs << action if User.current.allowed_to?(action, @project)
          end
                   
          tabs
        end
      end
    end
  end
end

unless ProjectsHelper.included_modules.include?(RedmineIssueToEmail::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, RedmineIssueToEmail::Patches::ProjectsHelperPatch)
end



