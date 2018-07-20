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

require 'net/imap'
require 'down'
require 'shellwords'
require 'open3'

class ArchiveIssuesJob < ActiveJob::Base
  queue_as :default
  
  def perform( _issue, _user, _settings, _issue_email_url )
        
    begin
      _issue_email_file = Down.download( _issue_email_url )
       store_to_imap(   _issue, _user, _settings, _issue_email_file.read )
       store_to_script( _issue, _user, _settings, _issue_email_file )
    ensure
      _issue_email_file.close rescue nil
      _issue_email_file.unlink rescue nil
    end

  end

private

  def store_to_script( _issue, _user, _settings, _issue_email_file )

    if _settings.present?
  
      if _settings.server_script.present?
    
        cmd = _settings.server_script
        # be careful with sequence of replacements
        cmd.gsub!(/%f/,   _issue_email_file.path )
        cmd.gsub!(/%u/,   _user.to_s )
        cmd.gsub!(/%pid/, _issue.project.id.to_s )
        cmd.gsub!(/%p/,   _issue.project.identifier )
        cmd.gsub!(/%id/,  _issue.id.to_s )
        cmd.gsub!(/%c/,   _issue.created_on.strftime("%FT%T") )
        cmd.gsub!(/%a/,   DateTime.now.strftime("%FT%T") )

        #should be last
        cmd.gsub!(/%s/,   Shellwords.escape(_issue.subject) )

        out, err, stat = Open3.capture3( cmd ) 
        exit_status = stat.exitstatus
        exit_status == 0 or raise Exception.new( "server script errored, result: #{err}" )        
      
      else 
       #silence
      end #if   

    else 
      raise Exception.new( "#{self.class}::#{__method__}: #{l(:label_issue_to_email_not_configured)}" )
    end #if
    
  end #def

  #------------------------------------------------------------------------------#
  def store_to_imap( _issue, _user, _settings, _issue_email_string  )

    if _settings.present?

      if _settings.protocol.present?

        protocol =  _settings.protocol
        host     =  _settings.host
        port     =  _settings.port
        login    =  _settings.username
        pwd      =  _settings.password
        use_ssl  =  _settings.use_ssl.present?
        verify   =  _settings.ssl_verify.present?
        folder   = _settings.imap_folder
        imap     = nil

        Timeout::timeout(15) do
          imap = Net::IMAP.new(host, port, use_ssl, nil, verify)
          imap.login(login, pwd) unless login.blank?
        end
        
        if imap
        
          imap_folders = imap.list("", "*")
          unless imap_folders.any? {|imap_folder| imap_folder.name == folder}
            raise Exception.new(l(:text_no_matching_folder, :folder=> folder.presence || l(:label_empty)))
          end 
    
          result = imap.select(folder)
          unless result.name == "OK"
            raise Exception.new(l(:text_imap_folder_not_selectable, :folder=> folder.presence || l(:label_empty)))
          end 
    
          result = imap.append(folder, _issue_email_string )
          unless result.name == "OK"
            raise Exception.new(l(:text_imap_could_not_upload, :folder=> folder.presence || l(:label_empty)))
          end 
        end #if
    
      else 
        #silence
      end #if   

    else 
      raise Exception.new( "#{self.class}::#{__method__}: #{l(:label_issue_to_email_not_configured)}")
    end #if
  
  ensure
    ###########################################################
    #  if login failed, ensure, we logoff                     #
    ###########################################################
    if imap && !imap.disconnected?
      imap.logout
      imap.disconnect
    end #if
  
  end #def
  
  
end #class