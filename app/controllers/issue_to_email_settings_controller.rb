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

class IssueToEmailSettingsController < ApplicationController
  layout 'admin'

  before_filter :find_project
  before_filter :authorize

  # ------------------------------------------------------------------------------------ #
  def index
  
  end #def

  # ------------------------------------------------------------------------------------ #
  def show
    redirect_to settings_project_path(:params => params)
  end #def
  
  # ------------------------------------------------------------------------------------ #
  def new
  
  end #def
  
  # ------------------------------------------------------------------------------------ #
  def create 
    redirect_to settings_project_path(:params => params)
  end #def
  
  # ------------------------------------------------------------------------------------ #
  def edit
    redirect_to settings_project_path(:params => params)
  end #def
  
  # ------------------------------------------------------------------------------------ #
  def update
    @issue_to_email_setting = IssueToEmailSetting.find(params[:issue_to_email_setting_id])
    @issue_to_email_setting.safe_attributes= params[:issue_to_email_setting]
    flash[:notice] = l(:notice_successful_update) if @issue_to_email_setting.save 
    redirect_to settings_project_path(:params => params)
  end #def
    
  # ------------------------------------------------------------------------------------ #
  def destroy
    IssueToEmailSetting.find(params[:issue_to_email_setting_id]).dissue_to_emailestroy
    redirect_to settings_project_path(:params => params)
  rescue Exception => e
    flash[:error] = "#{l(:error_unable_delete_issue_to_email_setting)}: Error: #{e.message}"
    redirect_to settings_project_path(:params => params)
  end #def 

  # ------------------------------------------------------------------------------------ #
  def test_imap

    @feedback_message_area = params[:feedback_message_area]
    @message = ""
    
    if User.current.allowed_to?( {controller: 'issue_to_email_settings', action: :test_imap }, @project ) || User.current.admin?
      
      if test_imap_connectivity( params )
        @message = "<div class='flash notice'>#{l(:text_issue_to_email_imap_successful)}</div>"
      else
        @message = "<div class='flash warning'>unknown error</div>"
        # will never get here - if test_imap_connectivity fails, an exception is raised
      end
      
      respond_to do |format|
          format.js do
              flash.discard
          end
      end
    
    else    
      raise Exception.new( "#{l(:label_better_email_not_authorized)}" )
      # will jump to rescue
    end
    
  rescue Exception => e
     respond_to do |format|
       format.js {
         @message  = "<div class='flash warning' onClick=\"$('#issue_to_email_error_details').toggle();\" >#{self.class}::#{__method__}: #{e.message}</div>\n"
         @message += "<div id='issue_to_email_error_details' class='flash warning' style='display: none;'>#{self.class}::#{__method__}: #{e.backtrace.join("<br />\n")}</div>\n"
         flash.discard
       }
       format.html {redirect_to :back}
     end  
  end 

private

  # ------------------------------------------------------------------------------------ #
  def test_imap_connectivity( params={} )
  
    protocol =  params[:issue_to_email_setting][:protocol]
    host     =  params[:issue_to_email_setting][:host]
    port     =  params[:issue_to_email_setting][:port]
    login    =  params[:issue_to_email_setting][:username]
    pwd      =  params[:issue_to_email_setting][:password]
    use_ssl  =  params[:issue_to_email_setting][:use_ssl].present?
    verify   =  params[:issue_to_email_setting][:ssl_verify].to_i == 1
    folder   =  params[:issue_to_email_setting][:imap_folder]
    imap     =  nil
    
    ###########################################################
    #  try to connect to imap server - else throw exception   #
    ###########################################################
    Timeout::timeout(15) do
      imap = Net::IMAP.new(host, port, use_ssl, nil, verify)
      imap.login(login, pwd) unless login.blank?
    end
    
    ###########################################################
    #  try to select IMAP folder                              #
    #  imap.lis(refname, mailbox)                             #
    #  refname  "": root, no prefix                           #
    #  mailbox "*": all mailboxes, including all sub-         #
    #               hierarchies                               #        
    ###########################################################
    if imap
      
      imap_folders = imap.list("", "*")
      unless imap_folders.any? {|imap_folder| imap_folder.name == folder}
        raise Exception.new(l(:text_no_matching_folder, :folder=> folder.presence || l(:label_empty)))
      end 
      
      imap.select(folder)
      unless imap_folders.any? {|imap_folder| imap_folder.name == folder}
        raise Exception.new(l(:text_imap_folder_not_selectable, :folder=> folder.presence || l(:label_empty)))
      end 
      
      imap.append(folder, "Mime-Type: 1.0\nSubject: Hello from Redmine Issue To Email\nFrom: Redmine Issue To Email Plugin\n\nHello World from Redmine Issue To Email" )
    end 

    ###########################################################
    #  when here, then test succeeded - return boolean true   #
    ###########################################################
    login.present?
    
    ###########################################################
    #  if login failed, ensure, we logoff                     #
    ###########################################################
  ensure
  
    if defined?(@imap) && @imap && !@imap.disconnected?
      @imap.disconnect
    end #if
    
  end #def


  
end #class
