class SubmissionMailer < ActionMailer::Base
  default from: 'yhd@york.ac.uk'
  layout 'mailer'

  SUBMISSION_EMAIL_ADDRESS = 'rainer.hind@york.ac.uk'

  def submission_email
    @email_address = params[:email_address]
    @sources = params[:sources]
    @notes = params[:notes]
    @dates = params[:dates]
    @quotes = params[:quotes]
    @places = params[:places]
    @word = params[:word]
    new_entry_param = params[:new_entry]
    if new_entry_param.present?
      if new_entry_param === 'true'
        @new_entry = true
      else
        @new_entry = false
      end
    end
    mail(to: SUBMISSION_EMAIL_ADDRESS, subject: 'YHD Submission Form Entry')
  end
end
