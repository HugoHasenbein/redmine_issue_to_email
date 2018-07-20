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

class IssueToEmailSetting < ActiveRecord::Base
  include Redmine::SafeAttributes
  unloadable
  
  belongs_to :project
  attr_protected :id

  safe_attributes 'protocol',
                  'host',
                  'port',
                  'username',
                  'password',
                  'use_ssl',
                  'ssl_verify',
                  'delete_unprocessed',
                  'imap_folder',
                  'server_script',
                  'status_id'
                  
                  
  attr_accessible :protocol, :host, :port, :username, :password, :use_ssl, :ssl_verify, 
      :delete_unprocessed, :imap_folder, :server_script, :status_id
      
  def to_s; name end
  
  
  def self.find_or_new( project_id )
    setting = IssueToEmailSetting.where(:project_id => project_id ).first
    unless setting.present?
      setting = IssueToEmailSetting.new
      setting.project_id = project_id
      
    end
    setting
  end
  
  private
  
end
