# Nhai Kanji — System Architecture

## Tổng quan hệ thống

Hệ thống gồm **3 repositories** phục vụ 2 nhóm người dùng (learner + admin):

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                 │
└──────┬──────────────────────┬───────────────────────┬───────────┘
       │                      │                       │
       ▼                      ▼                       ▼
┌──────────────┐   ┌───────────────────┐   ┌──────────────────┐
│  FE CLIENT   │   │    FE ADMIN       │   │    BACKEND       │
│  (luyenkanji)│   │   (nihongo_fe)    │   │  (nihongo_ecom)  │
│              │   │                   │   │                  │
│  Next.js SSG │   │  React 18 + MUI   │   │  Rails 8 API     │
│  Port: 3001  │   │  Port: 8080       │   │  Port: 3000      │
│  Static HTML │   │  SPA (CSR)        │   │  JSON API        │
└──────┬───────┘   └─────────┬─────────┘   └────────┬─────────┘
       │                     │                       │
       │      ┌──────────────┘                       │
       │      │    HTTP REST (JWT)                   │
       │      └──────────────────────────────────────┤
       │                                             │
       │         HTTP REST (JWT)                     │
       └─────────────────────────────────────────────┤
                                                     │
                                              ┌──────┴──────┐
                                              │   MySQL 8   │
                                              │   Redis 7   │
                                              └─────────────┘
```

---

## 1. FE Client — `luyenkanji`

### Thông tin chung

| Mục | Chi tiết |
|-----|---------|
| **Repo** | `/Users/haotruong/Desktop/luyenkanji` |
| **Framework** | Next.js 15 (App Router) |
| **Language** | TypeScript |
| **Styling** | Tailwind CSS 4.0 + Shadcn/ui (Radix UI) |
| **State** | Jotai + localStorage |
| **Auth** | Firebase Auth (Google OAuth) → chuyển sang JWT qua BE |
| **Build** | Static Site Generation (`output: "export"`) |
| **Deploy** | Static hosting (Vercel/Netlify/Cloudflare Pages) |
| **Port dev** | 3001 (default Next.js) |

### Chức năng

- **Tra cứu Kanji**: 2500+ trang kanji với JLPT level, bộ thủ, nghĩa Hán Việt
- **Composition Graph**: Đồ thị 2D/3D hiển thị quan hệ thành phần kanji (react-force-graph)
- **Stroke Animation**: Hoạt ảnh nét viết từ KanjiVG SVG data
- **Handwriting Recognition**: Canvas vẽ tay nhận dạng kanji (handwriting.js)
- **Tango (Từ vựng)**: Học từ vựng theo sách (Tango N5-N1, Minna, Mimikara, Tettei, SE)
- **SRS Flashcards**: Ôn tập lặp lại ngắt quãng (SM-2 algorithm, tính ở client)
- **Roadmap**: Lộ trình học 250 ngày
- **JLPT Test**: Thi thử JLPT N5-N1
- **Custom Vocab**: Người dùng tự thêm từ vựng cá nhân
- **Active Learning**: Chế độ học chủ động (kanji/hanviet/meaning mode)

### Data Flow

```
Static JSON files (data/)          User data (API → BE)
├── kanji/*.json (2500+)           ├── SRS cards + review logs
├── composition.json               ├── Roadmap progress
├── searchlist.json                 ├── Custom vocab
├── radicallist.json                ├── Tango lesson progress
├── tango/*.json                    ├── JLPT test results
└── animCJK/ (SVGs)                 └── User settings
```

- **Static data**: Đọc trực tiếp từ JSON files tại build time (SSG) hoặc client-side
- **User data**: Gọi API tới BE qua REST endpoints, auth bằng JWT
- **UI state**: localStorage (graph preferences, flashcard session, tab state)

### Scripts

```bash
npm run dev          # Dev server
npm run turbo        # Dev server (Turbo mode)
npm run build        # Production build (bật output: "export" trước)
npm run lint:fix     # Auto-fix ESLint
npm run format       # Prettier format
```

### Cấu trúc thư mục chính

```
src/
├── app/                    # Next.js App Router pages
│   ├── [id]/page.tsx       # Dynamic kanji pages (SSG via generateStaticParams)
│   ├── tango/              # Vocab learning pages
│   ├── roadmap/            # Roadmap pages
│   └── layout.tsx          # Root layout (providers, fonts, theme)
├── components/             # React components
│   ├── ui/                 # Shadcn/Radix UI primitives
│   ├── kanji.tsx           # Kanji info display
│   ├── graphs.tsx          # 2D/3D composition graphs
│   ├── search-input.tsx    # Virtual scrolling search (react-virtuoso)
│   └── draw-input.tsx      # Handwriting recognition canvas
├── lib/                    # Utilities, data loading, graph algorithms
│   ├── index.ts            # getKanjiDataLocal, getGraphData, findNodes
│   └── store.tsx           # Jotai atoms (graphPreferenceAtom)
└── styles/
    └── globals.css         # Tailwind + CSS custom properties (theming)
```

---

## 2. FE Admin — `nihongo_fe`

### Thông tin chung

| Mục | Chi tiết |
|-----|---------|
| **Repo** | `/Users/haotruong/Desktop/nihongo_fe` |
| **Framework** | React 18.2 (CRA — Create React App) |
| **Language** | TypeScript 5.2 |
| **UI Library** | Material-UI (MUI) v5.14 |
| **State** | React Context API + SWR (data fetching) |
| **Auth** | JWT (localStorage `accessToken`) |
| **Routing** | React Router v6 (`useRoutes`, lazy loading) |
| **Forms** | React Hook Form + Yup validation |
| **Charts** | ApexCharts |
| **Port dev** | 8080 |
| **Package Manager** | Yarn |

### Chức năng (cần implement)

Admin dashboard để quản lý toàn bộ dữ liệu người dùng:

| Module | Mô tả | API Endpoints |
|--------|--------|---------------|
| **Dashboard** | Thống kê tổng quan: users, reviews, active learners | `GET /api/v1/admin/stats` |
| **Users** | CRUD users, xem premium status, ban/unban | `GET/POST/PUT/DELETE /api/v1/admin/users` |
| **SRS Cards** | Xem SRS cards theo user, thống kê state distribution | `GET /api/v1/admin/srs_cards` |
| **Review Logs** | Xem lịch sử review, activity heatmap | `GET /api/v1/admin/review_logs` |
| **Roadmap** | Xem tiến trình roadmap theo user | `GET /api/v1/admin/roadmap_day_progresses` |
| **Custom Vocab** | Xem/quản lý từ vựng custom của users | `GET /api/v1/admin/custom_vocab_items` |
| **Feedbacks** | Duyệt feedback, reply, đổi status | `GET/PUT /api/v1/admin/feedbacks` |
| **Contacts** | Xem danh sách liên hệ khóa học | `GET /api/v1/admin/contacts` |
| **Tango Progress** | Xem tiến trình học tango theo user/book | `GET /api/v1/admin/tango_lesson_progresses` |
| **JLPT Results** | Xem kết quả thi JLPT | `GET /api/v1/admin/jlpt_test_results` |

### Cấu trúc thư mục chính

```
src/
├── api/                    # SWR hooks gọi API
├── auth/
│   └── context/jwt/        # JWT auth provider (login, logout, token management)
├── components/             # 91 reusable MUI components
│   ├── hook-form/          # RHF wrappers (RHFTextField, RHFSelect...)
│   ├── table/              # DataGrid wrappers
│   ├── upload/             # File upload
│   ├── chart/              # ApexChart wrappers
│   └── settings/           # Theme settings drawer
├── layouts/
│   ├── dashboard/          # Sidebar + Header + Main layout
│   └── auth/               # Auth pages layout
├── pages/
│   ├── auth/jwt/login.tsx  # Admin login page
│   └── dashboard/          # Dashboard pages (cần customize)
├── routes/
│   ├── paths.ts            # Route constants
│   └── sections/
│       ├── auth.tsx         # /auth/* routes
│       └── dashboard.tsx    # /dashboard/* routes (lazy loaded)
├── sections/               # Feature-specific UI sections
├── theme/                  # MUI theme (palette, typography, overrides)
├── locales/                # i18n (multi-language)
├── utils/
│   └── axios.ts            # Axios instance (baseURL: http://localhost:3000/)
└── types/                  # TypeScript type definitions
```

### Auth Flow

```
1. Admin truy cập /dashboard → AuthGuard check token
2. Chưa login → redirect /auth/jwt/login
3. POST /api/v1/admins/sign_in { email, password }
4. BE trả JWT token → lưu localStorage["accessToken"]
5. Mọi request kèm header: Authorization: Bearer <token>
6. Token hết hạn → redirect login
```

### Kết nối BE

```typescript
// src/utils/axios.ts
const HOST_API = process.env.REACT_APP_HOST_API; // http://localhost:3000/
const axiosInstance = axios.create({ baseURL: HOST_API });

// .env
REACT_APP_HOST_API=http://localhost:3000/
```

### Scripts

```bash
yarn install                    # Install dependencies
yarn start                      # Dev server (port 8080)
yarn build                      # Production build
yarn lint:fix                   # Auto-fix ESLint
yarn prettier                   # Format code
```

---

## 3. Backend — `nihongo_ecom`

### Thông tin chung

| Mục | Chi tiết |
|-----|---------|
| **Repo** | `/Users/haotruong/Desktop/nihongo_ecom` |
| **Framework** | Rails 8.0.2 (API-only mode) |
| **Language** | Ruby |
| **Database** | MySQL 8.0 (utf8mb4) |
| **Cache/Queue** | Redis 7 + Sidekiq |
| **Auth** | Devise + devise-jwt (JWT) |
| **Serializer** | jsonapi-serializer |
| **API Docs** | rswag (Swagger) |
| **Rate Limiting** | rack-attack |
| **Search** | Ransack |
| **Pagination** | Pagy |
| **Port** | 3000 |
| **Containerization** | Docker Compose |

### Database Schema (12 tables)

```
admins                      # Admin accounts (Devise)
users                       # End-user accounts
├── srs_cards               # SRS flashcard data (SM-2 state)
├── review_logs             # Review history (append-only)
├── roadmap_day_progresses  # Roadmap 250 ngày
├── custom_vocab_items      # Từ vựng tự thêm
├── user_settings           # Cài đặt cá nhân (1:1)
├── feedbacks               # Phản hồi từ users
├── contacts                # Liên hệ khóa học
├── tango_lesson_progresses # Tiến trình học tango
└── jlpt_test_results       # Kết quả thi JLPT
```

### Entity Relationships

```
admins (standalone - Devise auth)

users (1)
  ├── has_many   :srs_cards           (destroy)
  ├── has_many   :review_logs         (destroy)
  ├── has_many   :roadmap_day_progresses (destroy)
  ├── has_many   :custom_vocab_items  (destroy)
  ├── has_one    :user_setting        (destroy)
  ├── has_many   :feedbacks           (nullify)
  ├── has_many   :contacts            (nullify)
  ├── has_many   :tango_lesson_progresses (destroy)
  └── has_many   :jlpt_test_results   (destroy)
```

### API Endpoints (planned)

#### Admin Endpoints (`/api/v1/admins/`)

```
POST   /api/v1/admins/sign_in              # Admin login
DELETE /api/v1/admins/sign_out             # Admin logout
GET    /api/v1/admins/me                    # Current admin info
GET    /api/v1/admin/dashboard/stats        # Dashboard statistics
```

#### Admin Management Endpoints (`/api/v1/admin/`)

```
# Users
GET    /api/v1/admin/users                  # List users (pagy + ransack)
GET    /api/v1/admin/users/:id              # User detail
PUT    /api/v1/admin/users/:id              # Update user (premium, ban)
DELETE /api/v1/admin/users/:id              # Delete user

# SRS Cards (read-only for admin)
GET    /api/v1/admin/srs_cards              # List all / filter by user
GET    /api/v1/admin/srs_cards/stats        # Aggregate stats

# Review Logs (read-only)
GET    /api/v1/admin/review_logs            # List / filter
GET    /api/v1/admin/review_logs/heatmap    # Activity heatmap data

# Roadmap (read-only)
GET    /api/v1/admin/roadmap_day_progresses # List / filter by user

# Custom Vocab (read-only)
GET    /api/v1/admin/custom_vocab_items     # List / filter by user

# Feedbacks
GET    /api/v1/admin/feedbacks              # List (filter by status)
PUT    /api/v1/admin/feedbacks/:id          # Update status, reply

# Contacts
GET    /api/v1/admin/contacts               # List contacts

# Tango Progress (read-only)
GET    /api/v1/admin/tango_lesson_progresses # List / filter

# JLPT Results (read-only)
GET    /api/v1/admin/jlpt_test_results      # List / filter
```

#### User Endpoints (`/api/v1/users/`)

```
# Auth
POST   /api/v1/users/auth/google           # Google OAuth login/register
DELETE /api/v1/users/sign_out               # Logout (revoke JWT)
GET    /api/v1/users/me                     # Current user profile

# SRS
GET    /api/v1/users/srs_cards              # List user's SRS cards
POST   /api/v1/users/srs_cards              # Create SRS card
PUT    /api/v1/users/srs_cards/:id          # Update after review
GET    /api/v1/users/srs_cards/stats        # SRS statistics
GET    /api/v1/users/srs_cards/due          # Due cards for today

# Reviews
POST   /api/v1/users/review_logs            # Log a review
GET    /api/v1/users/review_logs/heatmap    # Activity heatmap

# Roadmap
GET    /api/v1/users/roadmap_day_progresses # User's roadmap progress
POST   /api/v1/users/roadmap_day_progresses # Mark day completed
GET    /api/v1/users/roadmap_day_progresses/streak # Current streak

# Custom Vocab
GET    /api/v1/users/custom_vocab_items     # List
POST   /api/v1/users/custom_vocab_items     # Create
PUT    /api/v1/users/custom_vocab_items/:id # Update
DELETE /api/v1/users/custom_vocab_items/:id # Delete
PUT    /api/v1/users/custom_vocab_items/reorder # Reorder positions

# Settings
GET    /api/v1/users/settings               # Get settings
PUT    /api/v1/users/settings               # Update settings

# Feedback
POST   /api/v1/users/feedbacks              # Submit feedback
GET    /api/v1/users/feedbacks              # List displayed feedbacks

# Contact
POST   /api/v1/users/contacts               # Submit contact form

# Tango
GET    /api/v1/users/tango_lesson_progresses           # List progress
PUT    /api/v1/users/tango_lesson_progresses/:id       # Update progress
POST   /api/v1/users/tango_lesson_progresses           # Create progress

# JLPT
GET    /api/v1/users/jlpt_test_results      # List results
POST   /api/v1/users/jlpt_test_results      # Save result
```

### Cấu trúc thư mục

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── health_controller.rb
│   └── api/v1/
│       ├── base_controller.rb
│       ├── admins/               # Admin auth (Devise)
│       │   ├── sessions_controller.rb
│       │   └── dashboard_controller.rb
│       ├── admin/                # Admin management (cần tạo)
│       │   ├── users_controller.rb
│       │   ├── feedbacks_controller.rb
│       │   └── ...
│       └── users/                # User-facing API (cần tạo)
│           ├── auth_controller.rb
│           ├── srs_cards_controller.rb
│           └── ...
├── models/
│   ├── admin.rb
│   ├── user.rb
│   ├── srs_card.rb
│   ├── review_log.rb
│   ├── roadmap_day_progress.rb
│   ├── custom_vocab_item.rb
│   ├── user_setting.rb
│   ├── feedback.rb
│   ├── contact.rb
│   ├── tango_lesson_progress.rb
│   └── jlpt_test_result.rb
├── serializers/                  # jsonapi-serializer (cần tạo)
└── services/                     # Business logic (cần tạo)

db/
├── migrate/                      # 12 migration files
└── schema.rb                     # Auto-generated schema

spec/
├── factories/                    # FactoryBot (11 factories)
├── models/                       # Model specs (10 files)
├── requests/                     # Request specs (cần tạo)
└── support/
```

### Docker Setup

```bash
# Start all services
docker compose -f docker-compose.dev.yml up -d

# Run migrations
docker compose -f docker-compose.dev.yml exec web bin/rails db:migrate

# Rails console
docker compose -f docker-compose.dev.yml exec web bin/rails console

# Run tests
docker compose -f docker-compose.dev.yml exec web bundle exec rspec

# View logs
docker compose -f docker-compose.dev.yml logs -f web
```

### Services (Docker Compose Dev)

| Service | Image | Port (host) | Mô tả |
|---------|-------|-------------|--------|
| web | Dockerfile.dev | 3000 | Rails API server |
| db | mysql:8.0.30 | 3310 | MySQL database |
| redis | redis:7-alpine | 6379 | Cache + Sidekiq broker |
| sidekiq | Dockerfile.dev | — | Background job worker |

---

## 4. Luồng dữ liệu chi tiết

### 4.1. User Authentication (Google OAuth)

```
FE Client                          Backend                         Google
   │                                  │                               │
   ├─── Google Sign-In popup ─────────┼───────────────────────────────►│
   │◄── Google ID Token ──────────────┼───────────────────────────────┤
   │                                  │                               │
   ├─── POST /api/v1/users/auth/google ──►│                           │
   │    { id_token: "..." }           │                               │
   │                                  ├── Verify token with Google ──►│
   │                                  │◄── Token valid, user info ────┤
   │                                  │                               │
   │                                  ├── Find or create User         │
   │                                  ├── Generate JWT                │
   │◄── { token, user } ─────────────┤                               │
   │                                  │                               │
   ├── Store JWT in localStorage      │                               │
   ├── All API calls with             │                               │
   │   Authorization: Bearer <jwt>    │                               │
```

### 4.2. SRS Review Flow

```
FE Client                          Backend                    Database
   │                                  │                           │
   ├── GET /srs_cards/due ────────────►│                           │
   │                                  ├── SELECT * FROM srs_cards │
   │                                  │   WHERE due_date <= NOW() ►│
   │◄── [{ kanji, state, ease }] ─────┤◄──────────────────────────┤
   │                                  │                           │
   │   User reviews card              │                           │
   │   SM-2 calculates new values     │                           │
   │                                  │                           │
   ├── PUT /srs_cards/:id ────────────►│                           │
   │   { state, ease, interval,       ├── UPDATE srs_cards ───────►│
   │     due_date }                   │                           │
   │                                  ├── INSERT review_logs ─────►│
   │◄── { updated_card } ────────────┤                           │
```

### 4.3. Admin Management Flow

```
FE Admin                           Backend                    Database
   │                                  │                           │
   ├── POST /admins/sign_in ──────────►│                           │
   │   { email, password }            ├── Devise authenticate ───►│
   │◄── { token } ───────────────────┤                           │
   │                                  │                           │
   ├── GET /admin/dashboard/stats ────►│                           │
   │                                  ├── Aggregate queries ──────►│
   │◄── { total_users, active,       ┤◄──────────────────────────┤
   │      reviews_today, ... }        │                           │
   │                                  │                           │
   ├── GET /admin/feedbacks?status=0 ─►│                           │
   │                                  ├── SELECT with ransack ────►│
   │◄── { feedbacks[], meta } ────────┤◄──────────────────────────┤
   │                                  │                           │
   ├── PUT /admin/feedbacks/:id ──────►│                           │
   │   { status: 1, admin_reply }     ├── UPDATE feedbacks ───────►│
   │◄── { updated_feedback } ────────┤                           │
```

---

## 5. Environment Variables

### FE Client (`luyenkanji/.env.local`)

```bash
# API
NEXT_PUBLIC_API_URL=http://localhost:3000/api/v1

# Firebase (giữ cho migration period)
NEXT_PUBLIC_FIREBASE_API_KEY=xxx
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=xxx
NEXT_PUBLIC_FIREBASE_PROJECT_ID=xxx
```

### FE Admin (`nihongo_fe/.env`)

```bash
PORT=8080
REACT_APP_HOST_API=http://localhost:3000/
REACT_APP_ASSETS_API=http://localhost:8080
```

### Backend (`nihongo_ecom/.env`)

```bash
# Database
DATABASE_URL=mysql2://root:password@db:3306/nihongo_ecom_development
DB_USER=root
NIHONGO_ECOM_DATABASE_PASSWORD=password
NIHONGO_ECOM_HOST=db

# Redis
REDIS_URL=redis://redis:6379

# JWT
DEVISE_JWT_SECRET_KEY=<secret>

# App
RAILS_ENV=development
APP_HOST=localhost:3000

# Google OAuth (cần thêm)
GOOGLE_CLIENT_ID=xxx
GOOGLE_CLIENT_SECRET=xxx
```

---

## 6. Deployment Architecture

### Production

```
┌──────────────────────┐     ┌──────────────────────┐
│   Vercel / Netlify   │     │   Vercel / Netlify   │
│   (Static Hosting)   │     │   (Static Hosting)   │
│                      │     │                      │
│   FE Client          │     │   FE Admin           │
│   nhaikanji.com      │     │   admin.nhaikanji.com│
└──────────┬───────────┘     └──────────┬───────────┘
           │                            │
           │     HTTPS (CORS)           │
           └────────────┬───────────────┘
                        │
                        ▼
              ┌──────────────────┐
              │   VPS / AWS ECS  │
              │                  │
              │   Rails API      │
              │   api.nhaikanji.com
              │                  │
              │   ┌────────────┐ │
              │   │ Sidekiq    │ │
              │   └────────────┘ │
              └────────┬─────────┘
                       │
              ┌────────┴─────────┐
              │                  │
        ┌─────┴─────┐    ┌──────┴─────┐
        │  MySQL 8   │    │  Redis 7   │
        │  (RDS)     │    │  (ElastiC) │
        └────────────┘    └────────────┘
```

### CORS Configuration (Rails)

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://nhaikanji.com",
            "https://admin.nhaikanji.com",
            "http://localhost:3001",    # FE Client dev
            "http://localhost:8080"     # FE Admin dev

    resource "/api/*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization],
      credentials: true
  end
end
```

---

## 7. Phân chia công việc

### Đã hoàn thành

- [x] Database design (10 tables)
- [x] Migrations (10 files)
- [x] Models với validations, enums, scopes
- [x] Factories + Model specs
- [x] Admin auth (Devise + JWT)
- [x] Docker Compose setup

### Cần làm — Backend

- [ ] CORS configuration
- [ ] User auth (Google OAuth → JWT)
- [ ] Admin management controllers (`/api/v1/admin/*`)
- [ ] User-facing controllers (`/api/v1/users/*`)
- [ ] Serializers (jsonapi-serializer)
- [ ] Request specs
- [ ] Swagger/rswag documentation
- [ ] Sidekiq jobs (nếu cần background processing)

### Cần làm — FE Admin

- [ ] Customize routes cho Nhai Kanji admin modules
- [ ] Tạo pages: Users, Feedbacks, Contacts, Dashboard stats
- [ ] Kết nối API endpoints
- [ ] Dashboard charts (ApexCharts — users growth, review activity)
- [ ] DataGrid cho list views (MUI X DataGrid)

### Cần làm — FE Client

- [ ] Tạo API service layer (axios/fetch → BE endpoints)
- [ ] Migrate auth từ Firebase → Google OAuth qua BE
- [ ] Kết nối SRS, Roadmap, Custom Vocab, Tango, JLPT tới BE
- [ ] Giữ Firebase Auth song song trong migration period
- [ ] Xóa Firebase dependencies sau khi migrate xong

---

## 8. Convention & Standards

### API Response Format

```json
// Success (single resource)
{
  "data": {
    "id": "1",
    "type": "user",
    "attributes": { "email": "user@example.com", "display_name": "User" }
  }
}

// Success (collection with pagination)
{
  "data": [
    { "id": "1", "type": "srs_card", "attributes": { ... } }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 10,
    "total_count": 200
  }
}

// Error
{
  "errors": [
    { "status": "422", "title": "Validation Error", "detail": "Kanji can't be blank" }
  ]
}
```

### Git Branch Strategy

```
main
├── develop
│   ├── feature/admin-users-crud
│   ├── feature/user-srs-api
│   ├── feature/fe-admin-dashboard
│   └── fix/cors-config
```

### Naming Conventions

| Layer | Convention | Ví dụ |
|-------|-----------|-------|
| DB tables | snake_case, plural | `srs_cards`, `review_logs` |
| DB columns | snake_case | `user_id`, `due_date` |
| Rails models | CamelCase, singular | `SrsCard`, `ReviewLog` |
| API endpoints | kebab-case | `/api/v1/admin/srs-cards` |
| JSON keys | snake_case | `{ "due_date": "..." }` |
| React components | PascalCase | `UserListPage`, `SrsCardTable` |
| React files | kebab-case | `user-list-page.tsx` |
| CSS classes | kebab-case | `.card-container` |
