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
    module ApplicationHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
        
          unloadable 
          
          alias_method_chain :authoring, :absolute_date
                    
        end #base
      end #self
      
      module InstanceMethods
      
        def authoring_with_absolute_date(created, author, options={})
          if params[:layoutemail].present?
            l(:label_added_time_on, 
              :author => link_to_user(author), 
              :on     => link_to( format_time(created), 
                                project_activity_path(@project, 
                                                      :from => User.current.time_to_date(created)
                                ), 
                                :title => format_time(created)
                         )
             ).html_safe
          else
            authoring_without_absolute_date(created, author, options)
          end
        end
        
      end #module
      
    end #module
  end #module
end #module

unless ApplicationHelper.included_modules.include?(RedmineIssueToEmail::Patches::ApplicationHelperPatch)
    ApplicationHelper.send(:include, RedmineIssueToEmail::Patches::ApplicationHelperPatch)
end


