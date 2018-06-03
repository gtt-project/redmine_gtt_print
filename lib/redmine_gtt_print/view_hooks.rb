module RedmineGttPrint
  class ViewHooks < Redmine::Hook::ViewListener

    render_on :view_layouts_base_html_head, inline: <<-END
        <%= stylesheet_link_tag 'gtt_print', plugin: 'redmine_gtt_print' %>
        <%= javascript_include_tag 'gtt_print', plugin: 'redmine_gtt_print' %>
    END

    render_on :view_issues_sidebar_issues_bottom,
      partial: "hooks/print_issue_form"

  end
end


