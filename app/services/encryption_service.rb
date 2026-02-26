# frozen_string_literal: true

class EncryptionService
  ALGORITHM = "aes-256-cbc"

  class << self
    def encrypt plaintext
      aes_key, iv, encrypted_data = aes_encrypt(plaintext)
      encrypted_key = rsa_encrypt(aes_key)

      {
        encrypted_key: Base64.strict_encode64(encrypted_key),
        iv: Base64.strict_encode64(iv),
        encrypted_data: Base64.strict_encode64(encrypted_data)
      }
    end

    private

    def aes_encrypt plaintext
      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.encrypt
      key = cipher.random_key
      iv = cipher.random_iv
      encrypted = cipher.update(plaintext) + cipher.final

      [key, iv, encrypted]
    end

    def rsa_encrypt data
      rsa_key = OpenSSL::PKey::RSA.new(rsa_public_key_pem)
      rsa_key.public_encrypt(data, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
    end

    def rsa_public_key_pem
      if ENV["RSA_PUBLIC_KEY_PATH"].present?
        File.read(ENV["RSA_PUBLIC_KEY_PATH"])
      else
        key = ENV.fetch("RSA_PUBLIC_KEY")
        key.gsub("\\n", "\n")
      end
    end
  end
end
