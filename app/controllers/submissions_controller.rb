# frozen_string_literal: true

class SubmissionsController < ApplicationController

  def index;end
  
  def create
    puts params
    SubmissionMailer
      .with(
        email_address: params[:email_address],
        content: params[:content]
      )
      .submission_email.deliver_now
    flash[:notice] = 'Submission sent. Thanks for your contribution!'
    redirect_to :root
  end
end
