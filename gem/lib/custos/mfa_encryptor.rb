# frozen_string_literal: true

require 'openssl'
require 'base64'

module Custos
  class MfaEncryptor
    ENCRYPTED_PREFIX = 'enc:'
    CIPHER = 'aes-256-gcm'
    IV_LENGTH = 12
    TAG_LENGTH = 16

    class << self
      def encrypt(plaintext)
        key = encryption_key
        return plaintext unless key

        cipher = OpenSSL::Cipher.new(CIPHER)
        cipher.encrypt
        iv = cipher.random_iv
        cipher.key = derive_key(key)
        cipher.auth_data = ''

        encrypted = cipher.update(plaintext) + cipher.final
        tag = cipher.auth_tag

        "#{ENCRYPTED_PREFIX}#{Base64.strict_encode64(iv + tag + encrypted)}"
      end

      def decrypt(ciphertext)
        key = encryption_key
        return ciphertext unless key
        return ciphertext unless ciphertext&.start_with?(ENCRYPTED_PREFIX)

        raw = Base64.strict_decode64(ciphertext.delete_prefix(ENCRYPTED_PREFIX))
        iv = raw.byteslice(0, IV_LENGTH)
        tag = raw.byteslice(IV_LENGTH, TAG_LENGTH)
        encrypted = raw.byteslice((IV_LENGTH + TAG_LENGTH)..)

        cipher = OpenSSL::Cipher.new(CIPHER)
        cipher.decrypt
        cipher.key = derive_key(key)
        cipher.iv = iv
        cipher.auth_tag = tag
        cipher.auth_data = ''

        cipher.update(encrypted) + cipher.final
      rescue ArgumentError, OpenSSL::Cipher::CipherError
        ciphertext
      end

      private

      def encryption_key
        Custos.configuration.mfa_encryption_key
      end

      def derive_key(key)
        OpenSSL::Digest::SHA256.digest(key)
      end
    end
  end
end
