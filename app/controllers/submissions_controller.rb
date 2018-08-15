# frozen_string_literal: true

class SubmissionsController < ApplicationController

  def index;end

  def create
    puts params
    SubmissionMailer
      .with(
        email_address: params[:email_address],
        new: params[:new],
        word: params[:word],
        dates: params[:dates],
        sources: params[:sources],
        quotes: params[:quotes],
        notes: params[:notes]
      )
      .submission_email.deliver_now
    flash[:notice] = 'Submission sent. Thanks for your contribution!'
    redirect_to :root
  end
end
