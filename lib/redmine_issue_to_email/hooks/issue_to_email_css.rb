module IssueToEmailCSS
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head, :partial => 'hooks/redmine_issue_to_email/style_sheet'
  end
end

