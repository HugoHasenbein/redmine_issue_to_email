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
    module ProjectPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          has_one :issue_to_email_setting

          def issue_to_email_setting 
            super || self.parent.presence && self.parent.issue_to_email_setting
          end #def
          
        end
      end

      module InstanceMethods
      end
      
    end
  end
end


unless Project.included_modules.include?(RedmineIssueToEmail::Patches::ProjectPatch)
    Project.send(:include, RedmineIssueToEmail::Patches::ProjectPatch)
end
