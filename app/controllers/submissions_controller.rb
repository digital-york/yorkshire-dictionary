# frozen_string_literal: true

class SubmissionsController < ApplicationController

  def index;end

  def create
    SubmissionMailer
      .with(
        email_address: params[:email_address],
        new_entry: params[:new_entry],
        word: params[:word],
        dates: params[:dates],
        sources: params[:sources],
        places: params[:places],
        quotes: params[:quotes],
        notes: params[:notes]
      )
      .submission_email.deliver_now
    flash[:success] = 'Submission sent. Thanks for your contribution!'
    redirect_to :root
  end
end
