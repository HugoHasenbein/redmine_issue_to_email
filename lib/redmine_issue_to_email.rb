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

Rails.configuration.to_prepare do

  # require patches
  require 'redmine_issue_to_email/patches/application_helper_patch'
  require 'redmine_issue_to_email/patches/projects_helper_patch'
  require 'redmine_issue_to_email/patches/project_patch'
  require 'redmine_issue_to_email/patches/issues_controller_patch'
  require 'redmine_issue_to_email/patches/issues_helper_patch'

  # require hooks
  require 'redmine_issue_to_email/hooks/issue_to_email_css'
  require 'redmine_issue_to_email/hooks/view_issues_context_menu_end'

  # register file type for responses
  Mime::Type.register "message/rfc822", :eml
  
end