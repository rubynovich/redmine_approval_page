module ApprovalPagePlugin
  module IssuesHelperPatch
    extend ActiveSupport::Concern
    included do
      alias_method_chain :show_detail, :approval_page
    end

    def show_detail_with_approval_page(detail, no_html=false, options={})
      if detail.property == 'watchers'
        if detail.prop_key == 'approver' && detail.value.nil? && detail.old_value.present?
          user = User.where(id: detail.old_value).first
          return l(:message_remove_approver, name: user.name).html_safe
        elsif ['approver','approvers'].include?(detail.prop_key) && detail.old_value.nil? && detail.value.present?
          users = User.where(id: detail.value.split(','))
          return (users.count > 1 ? l(:message_add_approvers, names: users.map(&:name).join(', ')) : l(:message_add_approver, name: users.first.name) ).html_safe
        elsif detail.prop_key == 'approved' && detail.old_value.nil? && detail.value.present?
          user = User.where(id: detail.old_value).first
          return l(:message_approver_approved)[true].html_safe
        else
          show_detail_without_approval_page(detail, no_html, options)
        end
      else
        show_detail_without_approval_page(detail, no_html, options)
      end
    end

  end
end