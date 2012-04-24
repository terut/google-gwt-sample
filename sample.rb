require 'bundler'
Bundler.require(:default)

require 'faraday'

claims = { 
    "iss" => "foofoo",
    "scope" => "https://www.googleapis.com/auth/analytics.readonly",
    "aud" => "https://accounts.google.com/o/oauth2/token",
    "exp" => (Time.now() + 3600).to_i,
    "iat" => Time.now().to_i
}

# OpenSSL::PKCS12 don't have sign method, So if you wanna use gem 'jwt', convert pem to p12.
# OpenSSL::PKCS12.new(pkcs12_path, "aaaa").sign raise undefined method error.
# When you download google private key, google show password you need by red color text.
#
# at Terminal:
#   $ openssl pkcs12 -in bar.p12 -out bar.pem
#   Password:
#
pem = File.read("bar.pem")
key = OpenSSL::PKey::RSA.new(pem, "aaaa")

jwt = JWT.encode(claims, key,"RS256")

conn = Faraday.new(url: "https://accounts.google.com") do |builder|
  builder.request  :url_encoded
  builder.response :logger
  builder.adapter  :net_http
end

params = {
  grant_type: "assertion",
  assertion_type: "http://oauth.net/grant_type/jwt/1.0/bearer",
  assertion: jwt
}

res = conn.post "/o/oauth2/token", params
p res.body
