# frozen_string_literal: true

class FirebaseSyncService
  FIRESTORE_BASE = "https://firestore.googleapis.com/v1"
  TOKEN_URI = "https://oauth2.googleapis.com/token"
  SCOPE = "https://www.googleapis.com/auth/datastore"
  PAGE_SIZE = 300

  def initialize
    @credentials = load_credentials
    @project_id = @credentials["project_id"]
    @access_token = nil
    @token_expires_at = Time.at(0)
  end

  # Fetch all documents from a top-level collection
  def fetch_collection collection_name
    documents = []
    page_token = nil

    loop do
      url = "#{FIRESTORE_BASE}/projects/#{@project_id}/databases/(default)/documents/#{collection_name}"
      params = { pageSize: PAGE_SIZE }
      params[:pageToken] = page_token if page_token

      response = authorized_get(url, params)
      body = JSON.parse(response.body)

      docs = body["documents"] || []
      documents.concat(docs)

      page_token = body["nextPageToken"]
      break unless page_token
    end

    documents
  end

  # Fetch all documents from a subcollection
  def fetch_subcollection parent_path, subcollection
    documents = []
    page_token = nil

    loop do
      url = "#{FIRESTORE_BASE}/#{parent_path}/#{subcollection}"
      params = { pageSize: PAGE_SIZE }
      params[:pageToken] = page_token if page_token

      response = authorized_get(url, params)
      body = JSON.parse(response.body)

      docs = body["documents"] || []
      documents.concat(docs)

      page_token = body["nextPageToken"]
      break unless page_token
    end

    documents
  end

  # Convert Firestore typed value to Ruby value
  def parse_firestore_value field
    return nil if field.nil?

    if field.key?("stringValue")
      field["stringValue"]
    elsif field.key?("integerValue")
      field["integerValue"].to_i
    elsif field.key?("doubleValue")
      field["doubleValue"].to_f
    elsif field.key?("booleanValue")
      field["booleanValue"]
    elsif field.key?("timestampValue")
      Time.parse(field["timestampValue"])
    elsif field.key?("nullValue")
      nil
    elsif field.key?("mapValue")
      parse_firestore_map(field["mapValue"])
    elsif field.key?("arrayValue")
      (field["arrayValue"]["values"] || []).map { |v| parse_firestore_value(v) }
    end
  end

  # Parse a Firestore map into a Ruby hash
  def parse_firestore_map map_value
    fields = map_value["fields"] || {}
    fields.transform_values { |v| parse_firestore_value(v) }
  end

  # Parse all fields of a Firestore document into a Ruby hash
  def parse_document doc
    fields = doc["fields"] || {}
    fields.transform_values { |v| parse_firestore_value(v) }
  end

  # Extract document ID from the full Firestore document name path
  def document_id doc
    doc["name"].split("/").last
  end

  private

  def load_credentials
    path = Rails.root.join("config", "nhaikanji-by-thocode-firebase-adminsdk-fbsvc-e765bf001a.json")
    JSON.parse(File.read(path))
  end

  def access_token
    return @access_token if @access_token && Time.current < @token_expires_at

    now = Time.current.to_i
    payload = { iss: @credentials["client_email"], scope: SCOPE, aud: TOKEN_URI, iat: now, exp: now + 3600 }

    private_key = OpenSSL::PKey::RSA.new(@credentials["private_key"])
    jwt_token = JWT.encode(payload, private_key, "RS256")

    response = HTTParty.post(TOKEN_URI, body: {
                               grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt_token
                             })

    result = JSON.parse(response.body)
    @access_token = result["access_token"]
    @token_expires_at = Time.current + result["expires_in"].to_i - 60
    @access_token
  end

  def authorized_get url, params = {}
    HTTParty.get(url, query: params, headers: {
                   "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json"
                 })
  end
end
