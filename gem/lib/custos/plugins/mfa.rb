# frozen_string_literal: true

require 'rotp'
require 'json'
require 'time'

module Custos
  module Plugins
    module Mfa
      SMS_CODE_LENGTH = 6
      SMS_CODE_EXPIRY = 5 * 60 # 5 minutes
      BACKUP_CODES_COUNT = 10

      def self.apply(model_class, **_options)
        model_class.has_many :custos_mfa_credentials,
                             class_name: 'Custos::MfaCredential',
                             as: :authenticatable,
                             dependent: :destroy

        model_class.include(InstanceMethods)
      end

      module InstanceMethods
        def setup_totp(issuer: 'Custos')
          secret = ROTP::Base32.random
          credential = find_or_build_mfa_credential('totp')
          credential.update!(secret_data: secret, enabled_at: nil)

          totp = ROTP::TOTP.new(secret, issuer: issuer)
          totp.provisioning_uri(respond_to?(:email) ? email : id.to_s)
        end

        def verify_totp(code)
          return false if respond_to?(:mfa_locked?) && mfa_locked?

          credential = enabled_mfa_credential('totp')
          return false unless credential

          secret = credential.secret_data
          return false unless secret

          totp = ROTP::TOTP.new(secret)
          result = totp.verify(code.to_s, drift_behind: 30, drift_ahead: 30).present?
          fire_mfa_verification_hook(result)
          result
        end

        def confirm_totp!(code)
          credential = custos_mfa_credentials.by_method('totp').first
          return false unless credential

          secret = credential.secret_data
          return false unless secret

          totp = ROTP::TOTP.new(secret)
          return false unless totp.verify(code.to_s, drift_behind: 30, drift_ahead: 30)

          credential.update!(enabled_at: Time.current)
          true
        end

        def totp_enabled?
          enabled_mfa_credential('totp').present?
        end

        def generate_backup_codes(count: BACKUP_CODES_COUNT)
          codes = Array.new(count) { SecureRandom.hex(6) }
          digests = codes.map { |code| Custos::TokenGenerator.digest(code) }

          credential = find_or_build_mfa_credential('backup_codes')
          credential.update!(secret_data: JSON.generate(digests), enabled_at: Time.current)

          codes
        end

        def verify_backup_code(code)
          return false if respond_to?(:mfa_locked?) && mfa_locked?

          credential = enabled_mfa_credential('backup_codes')
          return false unless credential

          result = consume_backup_code(credential, code)
          fire_mfa_verification_hook(result)
          result
        end

        def send_sms_code
          code = SecureRandom.random_number(10**SMS_CODE_LENGTH).to_s.rjust(SMS_CODE_LENGTH, '0')
          digest = Custos::TokenGenerator.digest(code)
          expiry = Time.current + SMS_CODE_EXPIRY

          credential = find_or_build_mfa_credential('sms')
          credential.update!(
            secret_data: JSON.generate({ digest: digest, expires_at: expiry.iso8601 }),
            enabled_at: Time.current
          )

          Custos::CallbackRegistry.fire(self.class, :sms_code_created, self, code)
          true
        end

        def verify_sms_code(code)
          return false if respond_to?(:mfa_locked?) && mfa_locked?

          credential = enabled_mfa_credential('sms')
          return false unless credential

          raw = credential.secret_data
          return false unless raw

          data = parse_json_hash(raw)
          return false if data.empty?
          return false if Time.iso8601(data['expires_at']) < Time.current

          result = Custos::TokenGenerator.secure_compare(
            data['digest'],
            Custos::TokenGenerator.digest(code)
          )

          invalidate_sms_credential(credential) if result
          fire_mfa_verification_hook(result)
          result
        rescue ArgumentError
          false
        end

        def mfa_enabled?
          totp_enabled? || enabled_mfa_credential('sms').present?
        end

        private

        def fire_mfa_verification_hook(success)
          Custos::CallbackRegistry.fire_hooks(self.class, :after_mfa_verification, self, success)
        end

        def consume_backup_code(credential, code)
          credential.with_lock do
            digest = Custos::TokenGenerator.digest(code)
            raw = credential.secret_data
            return false unless raw

            remaining = parse_json_array(raw)
            matched_index = remaining.index { |stored| Custos::TokenGenerator.secure_compare(stored, digest) }
            return false unless matched_index

            remaining.delete_at(matched_index)
            credential.update!(secret_data: JSON.generate(remaining))
          end

          true
        end

        def find_or_build_mfa_credential(method_name)
          custos_mfa_credentials.by_method(method_name).first ||
            custos_mfa_credentials.build(method: method_name)
        end

        def enabled_mfa_credential(method_name)
          custos_mfa_credentials.enabled.by_method(method_name).first
        end

        def invalidate_sms_credential(credential)
          credential.update!(secret_data: JSON.generate({ digest: '', expires_at: Time.current.iso8601 }))
        end

        def parse_json_array(json_string)
          parsed = JSON.parse(json_string)
          parsed.is_a?(Array) ? parsed : []
        rescue JSON::ParserError
          []
        end

        def parse_json_hash(json_string)
          parsed = JSON.parse(json_string)
          parsed.is_a?(Hash) ? parsed : {}
        rescue JSON::ParserError
          {}
        end
      end
    end
  end
end

Custos::Plugin.register(:mfa, Custos::Plugins::Mfa)
