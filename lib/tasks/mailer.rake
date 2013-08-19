desc <<-END_DESC
Send mails for approval requests.
END_DESC

namespace :redmine do

  task :send_approve_requests => :environment do
    Mailer.approve_requests
  end

end
