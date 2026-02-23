namespace :encryption do
  desc "Generate RSA 2048 key pair for API response encryption"
  task :generate_keys do
    rsa_key = OpenSSL::PKey::RSA.new(2048)

    private_key_pkcs1 = rsa_key.to_pem
    private_key_pkcs8 = rsa_key.private_to_pem
    public_key = rsa_key.public_key.to_pem

    puts "=== RSA Private Key - PKCS#8 (for CLIENT / Web Crypto API) ==="
    puts private_key_pkcs8
    puts

    puts "=== RSA Public Key (for SERVER ENV) ==="
    puts public_key
    puts

    # ENV format for server
    public_env = public_key.gsub("\n", "\\n")
    puts "=== Server .env ==="
    puts "RSA_PUBLIC_KEY=#{public_env}"
    puts

    # ENV format for client (Next.js)
    private_env = private_key_pkcs8.gsub("\n", "\\n")
    puts "=== Client .env (Next.js) ==="
    puts "NEXT_PUBLIC_RSA_PRIVATE_KEY=#{private_env}"
    puts

    # Save to files
    File.write("rsa_private.pem", private_key_pkcs8)
    File.write("rsa_public.pem", public_key)
    puts "Keys saved to rsa_private.pem (PKCS#8) and rsa_public.pem"
    puts "IMPORTANT: Keep rsa_private.pem secure — share only with the client app."
  end
end
