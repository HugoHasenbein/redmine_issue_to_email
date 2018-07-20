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

class CreateIssueToEmailSettings < ActiveRecord::Migration

  def self.up
    create_table :issue_to_email_settings do |t|
      t.column :project_id,             :integer
      t.column :protocol,               :string
      t.column :host,                   :string
      t.column :port,                   :string 
      t.column :username,               :string
      t.column :password,               :string
      t.column :use_ssl,                :boolean
      t.column :ssl_verify,             :boolean
      t.column :delete_unprocessed,     :boolean
      t.column :imap_folder,            :string
      t.column :server_script,          :string 
      t.column :status_id,              :integer
    end
  end

  def self.down
    drop_table :issue_to_email_settings
  end
end
