# frozen_string_literal: true

# Patch webpush 1.1.0 để tương thích với OpenSSL 3.0
# OpenSSL 3.0: PKey objects bất biến, không thể gọi generate_key hay các setter sau khi tạo
# Giải pháp: build key từ DER đúng format (RFC 5915), wrap PEM để tránh null-byte check

if OpenSSL::OPENSSL_VERSION_NUMBER >= 0x30000000
  module Webpush
    class VapidKey
      def initialize
        @curve = OpenSSL::PKey::EC.generate("prime256v1")
      end

      def self.from_keys(public_key, private_key)
        instance = allocate
        instance.instance_variable_set(:@curve, build_ec_key(
          Webpush.decode64(public_key),
          Webpush.decode64(private_key).rjust(32, "\x00")
        ))
        instance
      end

      def self.from_pem(pem)
        instance = allocate
        instance.instance_variable_set(:@curve, OpenSSL::PKey::EC.new(pem))
        instance
      end

      def public_key
        encode64(curve.public_key.to_octet_string(:uncompressed))
      end

      def public_key_for_push_header
        trim_encode64(curve.public_key.to_octet_string(:uncompressed))
      end

      def private_key
        encode64(curve.private_key.to_s(2).rjust(32, "\x00"))
      end

      def to_pem
        curve.to_pem
      end

      def public_key=(key)
        pub_bytes  = OpenSSL::BN.new(Webpush.decode64(key), 2).to_s(2)
        priv_bytes = curve.private_key ? curve.private_key.to_s(2).rjust(32, "\x00") : nil
        @curve = priv_bytes ? self.class.send(:build_ec_key, pub_bytes, priv_bytes) : self.class.send(:build_public_key, pub_bytes)
      end

      def private_key=(key)
        priv_bytes = OpenSSL::BN.new(Webpush.decode64(key), 2).to_s(2).rjust(32, "\x00")
        pub_bytes  = curve.public_key.to_octet_string(:uncompressed)
        @curve = self.class.send(:build_ec_key, pub_bytes, priv_bytes)
      end

      private

      # Build EC private key từ raw bytes theo đúng format OpenSSL 3.0 ASN1
      def self.build_ec_key(pub_bytes, priv_bytes)
        der = OpenSSL::ASN1::Sequence([
          OpenSSL::ASN1::Integer(OpenSSL::BN.new(1)),
          OpenSSL::ASN1::OctetString(priv_bytes),
          OpenSSL::ASN1::ASN1Data.new(
            [OpenSSL::ASN1::ObjectId("prime256v1")],
            0, :CONTEXT_SPECIFIC
          ),
          OpenSSL::ASN1::ASN1Data.new(
            [OpenSSL::ASN1::BitString(pub_bytes)],
            1, :CONTEXT_SPECIFIC
          )
        ]).to_der

        pem = "-----BEGIN EC PRIVATE KEY-----\n#{Base64.strict_encode64(der)}\n-----END EC PRIVATE KEY-----\n"
        OpenSSL::PKey::EC.new(pem)
      end
      private_class_method :build_ec_key

      def self.build_public_key(pub_bytes)
        der = OpenSSL::ASN1::Sequence([
          OpenSSL::ASN1::Sequence([
            OpenSSL::ASN1::ObjectId("id-ecPublicKey"),
            OpenSSL::ASN1::ObjectId("prime256v1")
          ]),
          OpenSSL::ASN1::BitString(pub_bytes)
        ]).to_der
        pem = "-----BEGIN PUBLIC KEY-----\n#{Base64.strict_encode64(der)}\n-----END PUBLIC KEY-----\n"
        OpenSSL::PKey::EC.new(pem)
      end
      private_class_method :build_public_key

      def encode64(bin)
        Webpush.encode64(bin)
      end

      def trim_encode64(bin)
        encode64(bin).delete("=")
      end
    end

    # Patch Encryption#encrypt: dùng EC.generate thay vì EC.new + generate_key
    module Encryption
      def encrypt(message, p256dh, auth)
        assert_arguments(message, p256dh, auth)

        group_name = "prime256v1"
        salt = Random.new.bytes(16)

        server = OpenSSL::PKey::EC.generate(group_name)
        server_public_key_bn = server.public_key.to_bn

        group = OpenSSL::PKey::EC::Group.new(group_name)
        client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
        client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

        shared_secret = server.dh_compute_key(client_public_key)
        client_auth_token = Webpush.decode64(auth)

        info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)

        prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: "SHA256", info: info).next_bytes(32)
        cek = HKDF.new(prk, salt: salt, info: "Content-Encoding: aes128gcm\0").next_bytes(16)
        nonce = HKDF.new(prk, salt: salt, info: "Content-Encoding: nonce\0").next_bytes(12)

        ciphertext = encrypt_payload(message, cek, nonce)
        serverkey16bn = [server_public_key_bn.to_s(16)].pack("H*")
        rs = ciphertext.bytesize
        raise ArgumentError, "encrypted payload is too big" if rs > 4096

        "#{salt}" + [rs].pack("N*") + [serverkey16bn.bytesize].pack("C*") + serverkey16bn + ciphertext
      end
    end
  end
end
