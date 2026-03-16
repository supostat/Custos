# frozen_string_literal: true

Rails.application.routes.draw do
  root "sessions#new"

  # Registration
  resources :registrations, only: %i[new create]
  get "email_confirmation/:token", to: "registrations#confirm_email", as: :confirm_email

  # Sessions (password login)
  resource :session, only: %i[new create destroy]

  # Magic Link
  get "magic_link/request", to: "sessions#magic_link_form", as: :magic_link_request
  post "magic_link/send", to: "sessions#send_magic_link", as: :send_magic_link
  get "magic_link/verify/:token", to: "sessions#verify_magic_link", as: :verify_magic_link

  # MFA
  scope "mfa" do
    get "setup", to: "mfa#setup", as: :mfa_setup
    post "confirm_totp", to: "mfa#confirm_totp", as: :mfa_confirm_totp
    get "verify", to: "mfa#verify_form", as: :mfa_verify
    post "verify", to: "mfa#verify"
    post "backup_codes", to: "mfa#generate_backup_codes", as: :mfa_backup_codes
    post "send_sms", to: "mfa#send_sms", as: :mfa_send_sms
    post "verify_sms", to: "mfa#verify_sms", as: :mfa_verify_sms
  end

  # Audit log
  resources :audit_logs, only: :index

  # Session management
  resources :session_management, only: %i[index destroy] do
    collection do
      delete :revoke_all
    end
  end

  # API
  namespace :api do
    resource :token, only: %i[create destroy]
    get "protected", to: "protected_resources#show"
  end
end
