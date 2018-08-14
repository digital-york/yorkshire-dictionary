class SubmissionMailer < ActionMailer::Base
  default from: 'yhd@york.ac.uk'
  layout 'mailer'

  SUBMISSION_EMAIL_ADDRESS = 'rainer.hind@york.ac.uk'

  def submission_email
    @content = params[:content]
    @email_address = params[:email_address]
    mail(to: SUBMISSION_EMAIL_ADDRESS, subject: 'YHD Submission Form Entry')
  end
end
