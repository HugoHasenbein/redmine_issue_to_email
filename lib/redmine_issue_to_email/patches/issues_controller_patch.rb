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
    module IssuesControllerPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
                
        base.class_eval do
          unloadable
          
          layout :choose_layout
          
          alias_method_chain :show, :eml
          alias_method :find_issue_to_email,      :find_issue
          alias_method :find_issues_to_emails,    :find_issues
          alias_method :authorize_issue_to_email, :authorize
          
          #
          # delete before filter authorize and later add again so that 
          # find issue is executed before authorize
          #
          skip_before_filter :authorize,                   :only => [:store, :bulk_store] 
          before_filter      :find_issue_to_email,         :only => [:store]
          before_filter      :find_issues_to_emails,       :only => [:bulk_store]
          before_filter      :find_issue_to_email_setting, :only => [:store] 
          before_filter      :authorize_issue_to_email,    :only => [:store, :bulk_store] 
          
          define_method :store, instance_method(:store)
          
          include IssuesHelper
          include CustomFieldsHelper
          
        end #base
      end #self
        
      module InstanceMethods
      
        #------------------------------------------------------------------------------#
        def store
          
          @issues = [@issue]
          @projects = [@project]
          bulk_store
          
        end #def
        
        #------------------------------------------------------------------------------#
        def bulk_store
          
          flash[:notice] = l(:label_issue_to_email_successfully_queued)
          
          @issues.each do |issue|
          
            @issue   = issue
            @project = issue.project
            find_issue_to_email_setting
            
            begin
              mark_stored
              ArchiveIssuesJob.perform_later( 
                  @issue, 
                  User.current, 
                  @issue_to_email_setting,
                  issue_url( @issue, 
                    :format => "eml", 
                    :layoutemail => true, 
                    :key => User.find(Setting["plugin_redmine_issue_to_email"]["export_user"].to_i).api_key
                  )
              )
              
            rescue Exception => e
              @message  = "#{self.class}::#{__method__}: #{e.message}"
              flash[:error] = @message
            end #begin
            
          end #each
          
          @project = @projects.size == 1 ? @projects.first : nil    
          redirect_back_or_default _project_issues_path( @project )
         
        end #def
        
        #------------------------------------------------------------------------------#
        def show_with_eml
          
          _rendered = false 
          respond_to do |format|
          
             format.eml  {
Rails.logger.info ".........hier 1"
              issue_email = issue_to_email(@issue, :key => params[:key])
Rails.logger.info ".............issue: #{@issue}"
Rails.logger.info ".............params[:key]: #{params[:key]}"
Rails.logger.info ".............issue_email[:key]: #{issue_email}"
              
              send_data issue_email, :type => 'message/rfc822', :filename => "#{@issue.project.identifier}-#{@issue.id}.eml" 
               _rendered = true
             }
             
             format.any  { } # important!
             
          end #respond_to     
            
          show_without_eml unless _rendered 
          
        end #def
                
                
        #------------------------------------------------------------------------------#
        #------------------------------------------------------------------------------#
        #private
          
        #------------------------------------------------------------------------------#
        def choose_layout
          params[:layoutemail].present? ? "issue_to_email"  : "base"
        end # def 
        
        
        #------------------------------------------------------------------------------#
        def find_issue_to_email_setting
            @issue_to_email_setting = @issue.project.issue_to_email_setting         
        end #def
        
        #------------------------------------------------------------------------------#
        def mark_stored
          
          if @issue_to_email_setting.present?
            
            if @issue.new_statuses_allowed_to.map(&:id).include?(@issue_to_email_setting.status_id)
            
              journal = @issue.init_journal(User.current)
              journal.details << JournalDetail.new(:property => 'issue_to_email', :prop_key => 'stored', :value => 'imap' )
              @issue.status_id_will_change!
              @issue.status_id = @issue_to_email_setting.status_id
              @issue.save
              journal.save
              @issue.reload
              
            elsif @issue_to_email_setting.status_id.blank?
            
             # silence - don't do anything 
            else
            
              status = IssueStatus.where(:id => @issue_to_email_setting.status_id).first
              raise Exception.new( l(:issue_to_email_cannot_store, :status => status.present? ? status.name : @issue_to_email_setting.status_id.to_s ) )
            end
          else 
          
            raise Exception.new( "#{self.class}::#{__method__}: #{l(:label_issue_to_email_not_configured)}" )
          end
            
        end #def
        
      end #module 
      
      module ClassMethods
      end #module 
      
    end #module
  end #module
end #module

unless IssuesController.included_modules.include?(RedmineIssueToEmail::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineIssueToEmail::Patches::IssuesControllerPatch)
end

