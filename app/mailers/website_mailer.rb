class WebsiteMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'
 
  def contact_us(website_contact)
    @website_contact = website_contact
    mail(subject: 'New contact request from website!', to: 'info@joshsoftware.com')
  end
end
