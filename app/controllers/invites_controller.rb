class InvitesController < ApplicationController
  require 'httparty'

  before_action :set_dropbox_api_token, only: [:create]

  def new
    @invite = Invite.new
  end

  def create
    @invite = Invite.new(invite_params)
    if @invite.save
      if send_dropbox_invite(@invite.email)
        redirect_to new_invite_path, notice: 'Invite was successfully sent.'
      else
        flash[:alert] = 'Failed to send invite.'
        render :new
      end
    else
      render :new
    end
  end

  def get_token
    authenticator = DropboxApi::Authenticator.new(ENV['DROPBOX_CLIENT'], ENV['DROPBOX_SECRET'])
    authorization_url = authenticator.auth_code.authorize_url
    redirect_to authorization_url, allow_other_host: true
  end

  def callback
    authenticator = DropboxApi::Authenticator.new(ENV['DROPBOX_CLIENT'], ENV['DROPBOX_SECRET'])
    access_token = authenticator.auth_code.get_token(params[:code])
    @dropbox_access_token = access_token.token
    # Save this token as needed. For now, we're just logging it.
    Rails.logger.info("Dropbox access token: #{@dropbox_access_token}")
    # Optionally, redirect to another action or page.
    redirect_to new_invite_path, notice: 'Dropbox token received successfully.'
  end

  private

  def invite_params
    params.require(:invite).permit(:email)
  end

  def set_dropbox_api_token
    @dropbox_api_token = ENV['DROPBOX_ACCESS_TOKEN']
  end

  def send_dropbox_invite(email)
    response = HTTParty.post(
      'https://api.dropboxapi.com/2/team/members/add',
      headers: {
        "Authorization" => "Bearer #{@dropbox_api_token}",
        "Content-Type": "application/json"
      },
      body: {
        new_members: [
          {
            member_email: email,
            member_given_name: email.split('@').first,
            member_surname: 'User',
            send_welcome_email: true,
            role: { ".tag": "member" }
          }
        ]
      }.to_json
    )

    if response.success?
      Rails.logger.info("Invite sent successfully: #{response.body}")
      true
    else
      Rails.logger.error("Dropbox API Error: #{response.body}")
      false
    end
  end
end
