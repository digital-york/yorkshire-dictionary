# frozen_string_literal: true

class SubmissionMailer < ActionMailer::Base
  default from: 'infodir-digital@york.ac.uk'
  layout 'mailer'

  SUBMISSION_EMAIL_ADDRESS = 'infodir-digital@york.ac.uk'

  def submission_email
    @email_address = params[:email_address]
    @sources = params[:sources]
    @notes = params[:notes]
    @dates = params[:dates]
    @quotes = params[:quotes]
    @places = params[:places]
    @word = params[:word]
    new_entry_param = params[:new_entry]

    # Checks if new_entry_param is true, only if there is a value present
    # @new_entry will be true if new_entry_param == 'true', false if it's
    # 'false', and nil otherwise.
    @new_entry = new_entry_param == 'true' if new_entry_param.present?

    mail(to: SUBMISSION_EMAIL_ADDRESS, subject: 'YHD Submission Form Entry')
  end
end
