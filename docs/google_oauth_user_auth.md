# Google OAuth User Authentication

## Flow

```
Frontend (Google Sign-In SDK) -> gets authorization code
  -> POST /api/v1/users/auth_google { code }
    -> Backend exchanges code for access_token from Google
    -> Uses access_token to call Google API for user info
    -> Finds or creates User (uid + provider)
    -> Generates JWT token via Warden::JWTAuth::UserEncoder
    -> Returns { access_token, user }
```

## Setup Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable "Google+ API" or "People API"
4. Go to **Credentials** -> **Create Credentials** -> **OAuth 2.0 Client IDs**
5. Set application type (Web application)
6. Add authorized redirect URIs
7. Copy **Client ID** and **Client Secret**

## Environment Variables

Add to `.env`:

```env
GOOGLE_CLIENT_ID=your_client_id_here
GOOGLE_CLIENT_SECRET=your_client_secret_here
GOOGLE_TOKEN_ENDPOINT=https://oauth2.googleapis.com/token
GOOGLE_REDIRECT_URI=your_redirect_uri_here
```

## API Endpoints

### User Auth

#### POST `/api/v1/users/auth_google`

Authenticate user with Google OAuth authorization code.

**Request:**
```json
{
  "code": "4/0AY0e-g..."
}
```

**Response (200):**
```json
{
  "success": true,
  "code": 200,
  "message": "Success",
  "data": {
    "code": 200,
    "message": "Success",
    "resource": {
      "data": {
        "id": "1",
        "type": "user",
        "attributes": {
          "id": 1,
          "email": "user@gmail.com",
          "display_name": "User Name",
          "photo_url": "https://...",
          "provider": "google",
          "is_premium": false,
          "premium_until": null
        }
      }
    },
    "token": "eyJhbGci..."
  }
}
```

### Admin User Management

All admin endpoints require admin JWT token in `Authorization: Bearer <token>` header.

#### GET `/api/v1/admins/users`

List users with pagination and search.

**Query params:**
- `q[email_cont]` - search by email (contains)
- `q[display_name_cont]` - search by display name
- `q[provider_eq]` - filter by provider
- `q[is_premium_eq]` - filter by premium status
- `per_page` - items per page (default: 20)
- `page` - page number

#### GET `/api/v1/admins/users/:id`

Get user details with stats (srs_cards_count, review_logs_count, etc.).

#### PATCH `/api/v1/admins/users/:id`

Update user premium status.

**Request:**
```json
{
  "user": {
    "is_premium": true,
    "premium_until": "2025-12-31T00:00:00Z"
  }
}
```

#### DELETE `/api/v1/admins/users/:id`

Delete a user and all associated data.

## Architecture

### Key Files

| File | Purpose |
|------|---------|
| `app/services/oauth_service.rb` | Exchange auth code for token, fetch user info from Google |
| `app/models/concerns/oauth_common.rb` | Find or create user from OAuth provider data |
| `app/models/user.rb` | User model with OauthCommon + Devise JWT |
| `app/controllers/api/v1/user_base_controller.rb` | Base controller with user JWT auth |
| `app/controllers/api/v1/users/omniauths_controller.rb` | Google OAuth endpoint |
| `app/controllers/api/v1/admins/users_controller.rb` | Admin user management CRUD |
| `app/serializers/user_serializer.rb` | User JSON:API serializer |
