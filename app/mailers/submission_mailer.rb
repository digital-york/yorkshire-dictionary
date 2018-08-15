class SubmissionMailer < ActionMailer::Base
  default from: 'yhd@york.ac.uk'
  layout 'mailer'

  SUBMISSION_EMAIL_ADDRESS = 'rainer.hind@york.ac.uk'

  def submission_email
    @email_address = params[:email_address]
    @sources = params[:sources]
    @notes = params[:sources]
    @dates = params[:sources]
    @quotes = params[:sources]
    @word = params[:word]
    @new = params[:new]
    mail(to: SUBMISSION_EMAIL_ADDRESS, subject: 'YHD Submission Form Entry')
  end
end
