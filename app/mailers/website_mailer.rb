class WebsiteMailer < ActionMailer::Base
  default :from => 'intranet@joshsoftware.com',
          :reply_to => 'hr@joshsoftware.com'
 
  def contact_us(website_contact)
    @website_contact = website_contact
    if @website_contact.role.eql?(WebsiteContact::CONTACT_US_JOB_SEEKER)
      mail(subject: 'New contact request from website!', to: 'careers@joshsoftware.com')
    else
      mail(subject: 'New contact request from website!', to: 'info@joshsoftware.com')
    end
  end
end
