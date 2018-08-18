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

require 'down'
require 'filemagic'

module RedmineIssueToEmail
  module Patches
    module IssuesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          
          alias_method_chain :show_detail, :issue_to_email_detail
          
          # ------------------------------------------------------------------------------#
          def issue_to_email( issue, assoc={} )
         
            archive_user        = User.find_by_api_key(assoc[:key]) || User.current
            email               = issue_base_email( issue )
            issue_html          = download_issue( issue, archive_user.api_key )
            issue_html          = replace_issue_attachment_links_with_cid( issue, issue_html )
            
            issue_html          = inline_css_style( issue_html )
            
            multipart           = (issue.attachments.length > 0) 
            email               = add_html_parts_to_email( email, issue_html, multipart )
            
            #
            # now add all issue attachments
            # because we may have duplicate filenames, things are complicated
            # avoid referring to attachment by filename
            # therefore, we keep a global_index by which we add the attachments
            #
            @global_index = 0
            email         = add_issue_attachments_to_email( email, issue, archive_user.api_key )
                        
            #
            # careful: the to_s-function causes message_id to be reinstantiated
            # careful: bcc field is deleted, when email ist called with .to_s
            # we must call .to_s, else there will be nothing to save
            # email.raw_source is only created on .to_s
            #       
            email.ready_to_send!
            email.to_s
        
          end #def 
        
          # ------------------------------------------------------------------------------#
          def issue_base_email( issue )
        
            #
            # create a message id
            #
            issue_message_id = "<#{issue.project.identifier}-#{issue.id}@#{Setting.host_name}>"
          
            #
            # make basic mail trunk
            #
            email = Mail.new do     
              from               ""
              to                 ""
              cc                 ""
              bcc                ""
              subject            issue.subject
              date               DateTime.now.strftime("%a, %d %b %Y %H:%M:%S %z")   
              message_id         issue_message_id
            end #Mail.new
            
            #
            # set custom mail headers, which may be useful for email clients
            # or email archiovers that can analyze and peruse maikl headers
            #
            email.header['X-Mailer']= "Redmine Better Issues Plugin"
          
            #
            # set referennces, so that email clients can connect
            # related issues with each other
            #
            refs = get_relations( issue ).map {|rel_issue| "<#{rel_issue.project.identifier}-#{rel_issue.id}@#{Setting.host_name}>" }
            email.header['References']= refs if refs.length > 0
            
            #
            # set mail headers to issue attribute values
            #
            email.header['X-Redmine-Host'] =              Setting.host_name
            email.header['X-Redmine-Project']=            issue.project.identifier
            email.header['X-Redmine-Status']=             issue.status_id.to_s
            email.header['X-Redmine-Priority']=           issue.priority_id.to_s
            email.header['X-Redmine-Assigned_to']=        issue.assigned_to_id.to_s
            email.header['X-Redmine-Category']=           issue.category_id.to_s
            email.header['X-Redmine-Fixed-Version']=      issue.fixed_version_id.to_s
            email.header['X-Redmine-Parent-Issue']=       issue.parent_issue_id.to_s 
            email.header['X-Redmine-Start-Date']=         format_date(issue.start_date)
            email.header['X-Redmine-Due-Date']=           format_date(issue.due_date)
            email.header['X-Redmine-Estimated-Hours']=    issue.estimated_hours.to_s
            email.header['X-Redmine-Done-Ratio']=         issue.done_ratio.to_s
          
            #
            # set mail headers to custom field values
            #
            values = issue.visible_custom_field_values
            values.each do |value|
             email.header["X-Redmine-Custom-Field-#{I18n.transliterate(value.custom_field.name, replacement = "-" ).gsub("\ ", "_")}"]= show_value(value)
            end
            
            # 
            # keep export / archive time
            #
            Time.zone = User.current.pref['time_zone'].presence || Rails.application.config.time_zone.presence || "UTC"
            email.header['X-Redmine-Export-Time']= DateTime.now.strftime("%d. %b %Y %H:%M:%S (%Z)")
          
            email
          
          end #def
       
       
          # ------------------------------------------------------------------------------#
          def download_issue( _issue, _api_key )

            #
            # create issue download url as defined in Redmine global settings
            #
            _issue_eml_url = issue_url( _issue, 
                                        :format => "html", 
                                        :layoutemail => true, 
                                        :key => _api_key
                             )
                             
            #
            # download issue via API call 
            #
            begin
              _issue_html_file = Down.download( _issue_eml_url )
              _issue_html = File.read( _issue_html_file.path)
            ensure
              _issue_html_file.close rescue nil
              _issue_html_file.unlink rescue nil
            end
          
            #
            # remove superfluous newlines / carriage returns and whitespace
            #
            if _issue_html.present?
              _issue_html.gsub!(/[\r\n]+/m, " ").squish!
              _issue_html
            else
              ""
            end 
          end #def
          
          # ------------------------------------------------------------------------------#
          def inline_css_style( issue_html )
        
            #
            # inline css or copy css -depending on compatibility selection
            #
            issue_doc = Roadie::Document.new(issue_html)
            issue_doc.asset_providers = [
              Roadie::FilesystemProvider.new( Rails.root.join('public') )
            ]
            
            # full transform css to inline css 
            issue_doc.keep_uninlinable_css = true
            if Setting[:host_name].present? 
              issue_doc.url_options = {host: "#{Setting[:host_name]}", protocol: "#{Setting[:protocol]}"} 
            else
              @guessed_host_and_path = request.host_with_port.dup
              @guessed_host_and_path << ('/'+ Redmine::Utils.relative_url_root.gsub(%r{^\/}, '')) unless Redmine::Utils.relative_url_root.blank?
              issue_doc.url_options = {host: @guessed_host_and_path, protocol: "#{Setting[:protocol]}"} 
            end #if
            issue_html = issue_doc.transform
            
            issue_html
          end #def 
                    
          
          # ------------------------------------------------------------------------------#
          def replace_issue_attachment_links_with_cid( issue, issue_html )
        
            #
            # search urls by issue attachments and replace url with cid: to attachments
            #          
            issue.attachments.each do |issue_attachment|
             
              case Setting['plugin_redmine_issue_to_email']['export_compatibility'] 
            
                #
                # 0 - experimental
                # 1 - apple
                # 2 - thunderbird
                # 3 - outlook
                #
            
                when '0', '2', '3' # experimental, thunderbird and outlook
                
                  #
                  # replace thumbnail urls (url structure likely highly redmine version specific)
                  #
                  url = "\/attachments\/thumbnail\/#{issue_attachment.id}[^\"^\']*"
                  pattern = /src=(?:"#{url}"|'#{url}')/i
                  issue_html.gsub!(pattern,  "src='cid:#{issue_attachment.id}@thumbnails'")
                
                  #
                  # replace srcset urls (url structure likely highly redmine version specific)
                  #
                  url = "\/attachments\/thumbnail\/#{issue_attachment.id}[^\"^\']*"
                  pattern = /srcset=(?:"#{url}"|'#{url}')/i
                  issue_html.gsub!(pattern,  "src='cid:#{issue_attachment.id}@thumbnails'")
                  
                when '1' # apple
                  #
                  # this works for apple mail: images with link to mail attachments
                  #
                  url = "\/attachments\/thumbnail\/#{issue_attachment.id}[^\"^\']*"
                  pattern = /src=(?:"#{url}"|'#{url}')/i
                  issue_html.gsub!(pattern,  "src='cid:#{issue_attachment.id}'")
                  
                  #
                  # replace srcset urls (url structure likely highly redmine version specific)
                  #
                  url = "\/attachments\/thumbnail\/#{issue_attachment.id}[^\"^\']*"
                  pattern = /srcset=(?:"#{url}"|'#{url}')/i
                  issue_html.gsub!(pattern,  "src='cid:#{issue_attachment.id}'")
              end
              
              if Setting[:host_name].present?
                protocol_host_name_pattern = Regexp.escape("#{Setting[:protocol]}://#{Setting[:host_name]}")
              else
                guessed_host_and_path = request.host_with_port.dup
                guessed_host_and_path << ('/'+ Redmine::Utils.relative_url_root.gsub(%r{^\/}, '')) unless Redmine::Utils.relative_url_root.blank?
                protocol_host_name_pattern = Regexp.escape("#{Setting[:protocol]}://#{guessed_host_and_path}")
              end #if

              #
              # replace attachment paths (path structure is likely highly redmine version specific)
              #
              path = "\/attachments/#{issue_attachment.id}\/#{URI.escape(issue_attachment.filename)}[^\"^\']*"
              pattern1 = /href=(?:"#{path}"|'#{path}')/i
              pattern2 = /src=(?:"#{path}"|'#{path}')/i
              issue_html.gsub!(pattern1,  "href='cid:#{issue_attachment.id}'")
              issue_html.gsub!(pattern2,  "src='cid:#{issue_attachment.id}'")
              
              #
              # replace attachment urls (url structure is likely highly redmine version specific)
              # reuse path variable from above
              #
              url = protocol_host_name_pattern + path
              pattern1 = /href=(?:"#{url}"|'#{url}')/i
              pattern2 = /src=(?:"#{url}"|'#{url}')/i
              issue_html.gsub!(pattern1,  "href='cid:#{issue_attachment.id}'")
              issue_html.gsub!(pattern2,  "src='cid:#{issue_attachment.id}'")
              
              #
              # replace attachment download paths (path structure is likely highly redmine version specific)
              #
              path = "\/attachments\/download\/#{issue_attachment.id}\/#{URI.escape(issue_attachment.filename)}[^\"^\']*"
              pattern = /href=(?:"#{path}"|'#{path}')/i
              issue_html.gsub!(pattern,  "href='cid:#{issue_attachment.id}'")
              
              #
              # replace attachment download urls (url structure is likely highly redmine version specific)
              # reuse path variable from above
              #
              url = protocol_host_name_pattern + path
              pattern = /href=(?:"#{url}"|'#{url}')/i
              issue_html.gsub!(pattern,  "href='cid:#{issue_attachment.id}'")

            end #do
            issue_html
          end #def
          
          
          # ------------------------------------------------------------------------------#
          def add_html_parts_to_email( email, issue_html, multipart )
        
            #
            # if attachments exist, create multipart email
            #
            if( multipart )
              email.content_type = "multipart/related;"
              html_part = Mail::Part.new do |html| 
                  html.content_type "text/html;"
                
                  html.body issue_html
                  #html.body [issue_html].pack('M') # encode qouted-printable
                  #html.body [issue_html].pack('m75') # quoted-printable mit 75 Zeichen Breite
                
                  #html.content_transfer_encoding('quoted-printable')
                  #html.content_transfer_encoding('base64')
                  html.content_transfer_encoding('8Bit') # no encoding
                
              end #html_part           
              email.add_part( html_part )  # container is new part            
              
            #
            # if attachments do not exist, create one-part email
            #
            else
          
              email.content_type = "text/html;" # we have no attachments
            
              email.body issue_html
              #email.body [issue_html].pack('M') # encode qouted-printable  
              #email.body [issue_html].pack('m75') # encode qouted-printable  
            
              #email.content_transfer_encoding('quoted-printable')  
              #email.content_transfer_encoding('base64')
              email.content_transfer_encoding('8Bit') # no encoding
              
            end #if
            email
          
          end #def 
        
        
          # ------------------------------------------------------------------------------#
          def add_issue_attachments_to_email (email, issue, key )
         
            archive_user = User.find_by_api_key(key)
        
            #
            # first add issue attachments to email
            #
            if issue.attachments.length > 0 && archive_user && issue.attachments_visible?(archive_user) 
              issue.attachments.each_with_index do |issue_attachment, index|
                #
                # we must mask text/html and text/plain, because .txt and .html files 
                # will be added as body parts; therefore, we add them as octet-stream.
                # this will make sure they get base64 encoded and masked from
                # the rest of the email body
                #
                  my_mime = "application/octet-stream"
                  email.attachments[issue_attachment.filename]= { :mime_type => my_mime,
                                                                  :data => Base64.encode64( File.read(issue_attachment.diskfile) ),
                                                                  :transfer_encoding => "base64" } 
                email.attachments[@global_index].header['Content-Id']= "<#{issue_attachment.id.to_s}>" 
                            
                @global_index += 1
                
              end #each_with_index
            end #if   
          
            if Setting.thumbnails_enabled?
              #
              # second add issue attachment thumbnails to email
              #
              case Setting['plugin_redmine_issue_to_email']['export_compatibility'] 
            
                #
                # 0 - experimental
                # 1 - apple
                # 2 - thunderbird
                # 3 - outlook
                #
            
                when '0', '2', '3' # experimental, thunderbird and outlook
                  if issue.attachments.length > 0 && archive_user && issue.attachments_visible?(archive_user) 
                    issue.attachments.each_with_index do |issue_attachment, index|
            
                      #
                      # try to determine the correct mime type of the thumbnail
                      # because thumbnails have extension .thumb, we must
                      # determine mime type by file contents
                      #
                      if issue_attachment.thumbnail.present?
                      mime_type = ""
                      File.open(issue_attachment.thumbnail) {|f| mime_type = MimeMagic.by_magic(f).try(:type) }
                      #mime_type = FileMagic.new( FileMagic::MAGIC_MIME ).file( issue_attachment.thumbnail )
                      match = mime_type.match( /\A[^;\ ]*/i )
                      mime = ( match ? match[0] : mime_type )
                      fileext = Rack::Mime::MIME_TYPES.invert[mime].presence.to_s
                    
                      filename = "thumbnail-#{@global_index}.#{issue_attachment.id}#{fileext}"
                      email.attachments[filename]= { :data => Base64.encode64( File.read(issue_attachment.thumbnail)),
                                                     :transfer_encoding => "base64"
                                                    }
                      email.attachments[@global_index].header['Content-Id']= "<#{issue_attachment.id.to_s}@thumbnails>"    
                      email.attachments[@global_index].header['Content-Disposition']= "inline"    
                      @global_index += 1
                      end
                    end 
                  end
                when '1'
                # if apple, then don't attach thumbnails
              end #case
            end #if
          
            email    
        
          end #def 
        
        
        
          # ------------------------------------------------------------------------------#
          def get_relations( issue )
        
            relations = []
        
            # 1. find all ancestors
            # "<#{ancestor.id}@#{ancestor.project}>"
            ancestors = issue.root? ? [] : issue.ancestors.visible.to_a
            ancestors.each do |ancestor|
              relations << ancestor 
            end

            # 2. find all descendants
            descendants = issue.descendants.visible.to_a
            descendants.each do |descendant|
              relations << descendant 
            end

            # 3. find all related
            issue_relations = issue.relations.select {|r| r.other_issue(issue) && r.other_issue(issue).visible? }
        
            issue_relations.each do |relation|
              other_issue = relation.other_issue(issue)
              relations << other_issue 
            end
        
            relations    
          end # def
        
        # ------------------------------------------------------------------------------#
        def issues_ready_to_export?( _issues )
        
          _issues.each do |_issue|
          
            #
            # not ready if no setting exist
            #
            return false if _issue.project.issue_to_email_setting.blank?
            
            #
            # only ready if new status is blank (no change) or is allowed
            # 
            #
            return false unless _issue.project.issue_to_email_setting.status_id.blank? ||
                                _issue.new_statuses_allowed_to.map(&:id).include?( 
                                  _issue.project.issue_to_email_setting.status_id 
                                )
          end #do
          
          return true
          
        end #def
        
        end #base
      end #self

      
      module InstanceMethods
      
        # ------------------------------------------------------------------------------#
        def show_detail_with_issue_to_email_detail(detail, no_html=false, options={})
          s = show_detail_without_issue_to_email_detail(detail, no_html, options)
          if detail.property == "issue_to_email"
            if no_html
              case detail.value
                when 'imap'
                  s = l(:label_issue_to_email_stored)
              end
            else
              case detail.value
                when 'imap'
                  s = content_tag('strong', l(:label_issue_to_email_stored) )
              end
            end 
          end #if
          s.present? ? s.html_safe : ""
        end #def
        
        # ------------------------------------------------------------------------------#
        # ------------------------------------------------------------------------------#
      end #module
    end #module
  end #module
end #module

unless IssuesHelper.included_modules.include?(RedmineIssueToEmail::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, RedmineIssueToEmail::Patches::IssuesHelperPatch)
end


