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
    module ApplicationControllerPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
                
        base.class_eval do
          unloadable
          
          alias_method_chain :require_login, :eml

        end #base
      end #self
        
      module InstanceMethods

		def require_login_with_eml
		  if !User.current.logged?
			# Extract only the basic url parameters on non-GET requests
			if request.get?
			  url = request.original_url
			else
			  url = url_for(:controller => params[:controller], :action => params[:action], :id => params[:id], :project_id => params[:project_id])
			end
			respond_to do |format|
			  format.html {
				if request.xhr?
				  head :unauthorized
				else
				  redirect_to signin_path(:back_url => url)
				end
			  }
			  # only change here
			  format.any(:atom, :pdf, :csv, :eml) {
				redirect_to signin_path(:back_url => url)
			  }
			  format.xml  { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="Redmine API"' }
			  format.js   { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="Redmine API"' }
			  format.json { head :unauthorized, 'WWW-Authenticate' => 'Basic realm="Redmine API"' }
			  format.any  { head :unauthorized }
			end
			return false
		  end
		  true
		end #def
  
      end #module      

      module ClassMethods
      end #module 
      
    end #module
  end #module
end #module

unless ApplicationController.included_modules.include?(RedmineIssueToEmail::Patches::ApplicationControllerPatch)
  ApplicationController.send(:include, RedmineIssueToEmail::Patches::ApplicationControllerPatch)
end

