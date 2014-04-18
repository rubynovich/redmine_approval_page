module ApprovalPagePlugin
  module IssuesHelperPatch
    extend ActiveSupport::Concern
    included do
      alias_method_chain :show_detail, :approval_page
    end

    def show_detail_with_approval_page(detail, no_html=false, options={})
      if detail.property == 'watchers'
        if detail.prop_key == 'approver' && ((detail.old_value.to_s.split(',') - detail.value.to_s.split(',')).count > 0)
          user = User.where(id: (detail.old_value.to_s.split(',') - detail.value.to_s.split(','))).first
          return ::I18n.t(:message_remove_approver_gender, name: user.name)["g#{user.try(:gender).to_s}"].html_safe
        elsif ['approver','approvers'].include?(detail.prop_key) && ((detail.value.to_s.split(',') - detail.old_value.to_s.split(',')).count > 0)
          users = User.where(id: (detail.value.to_s.split(',') - detail.old_value.to_s.split(',')))
          return (users.count > 1 ? ::I18n.t(:message_add_approvers, names: users.map(&:name).join(', ')) : ::I18n.t(:message_add_approver_gender, name: users.first.name)["g#{users.first.try(:gender).to_s}"] ).html_safe
        elsif detail.prop_key == 'approved' && ((detail.value.to_s.split(',') - detail.old_value.to_s.split(',')).count > 0)
          #user = User.where(id: detail.old_value).first
          return ::I18n.t(:message_approver_approved)[true].html_safe
        elsif detail.prop_key == 'approved' && ((detail.old_value.to_s.split(',') - detail.value.to_s.split(',')).count > 0)
          return ::I18n.t(:message_approver_approved)[false].html_safe
        else
          show_detail_without_approval_page(detail, no_html, options)
        end
      else
        show_detail_without_approval_page(detail, no_html, options)
      end
    end

  end
end