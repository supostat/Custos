# frozen_string_literal: true

require 'argon2'

module Custos
  module Plugins
    module Password
      DEFAULT_MIN_LENGTH = 8
      DEFAULT_MAX_LENGTH = 128
      DUMMY_PASSWORD_DIGEST = Argon2::Password.create('custos-timing-protection')

      def self.apply(model_class, **options)
        model_class.include(InstanceMethods)
        model_class.extend(ClassMethods)

        min = options.fetch(:min_length, DEFAULT_MIN_LENGTH)
        max = options.fetch(:max_length, DEFAULT_MAX_LENGTH)
        model_class.validates :password, length: { minimum: min, maximum: max }, if: :password_changed?

        if options[:require_uppercase]
          model_class.validates :password, format: { with: /[A-Z]/, message: 'must contain an uppercase letter' },
                                           if: :password_changed?
        end

        if options[:require_digit]
          model_class.validates :password, format: { with: /\d/, message: 'must contain a digit' },
                                           if: :password_changed?
        end

        if options[:require_special]
          model_class.validates :password,
                                format: { with: /[^A-Za-z0-9]/, message: 'must contain a special character' },
                                if: :password_changed?
        end

        model_class.after_save :clear_password_instance_variable, if: :password_changed?
      end

      module InstanceMethods
        attr_reader :password

        def password=(plain_password)
          @password = plain_password
          @password_changed = true
          self.password_digest = plain_password.present? ? Argon2::Password.create(plain_password) : nil
        end

        def authenticate_password(plain_password)
          return false if password_digest.blank?

          verified = Argon2::Password.verify_password(plain_password, password_digest)
          Custos::CallbackRegistry.fire_hooks(self.class, :after_authentication, self, verified)
          verified
        rescue Argon2::ArgonHashFail
          false
        end

        private

        def password_changed?
          @password_changed == true
        end

        def clear_password_instance_variable
          @password = nil
          @password_changed = false
        end
      end

      module ClassMethods
        def find_by_email_and_password(email:, password:)
          record = find_by(email: email)

          unless record
            Argon2::Password.verify_password(password, DUMMY_PASSWORD_DIGEST)
            return nil
          end

          return nil if record.respond_to?(:locked?) && record.locked?

          record.authenticate_password(password) ? record : nil
        end
      end
    end
  end
end

Custos::Plugin.register(:password, Custos::Plugins::Password)
