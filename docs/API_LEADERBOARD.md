# Leaderboard API

## Overview

Public endpoint (no authentication required) that returns the top learners ranked by total review count. Data is pre-computed by a background job and cached in Redis for 10 minutes.

## Endpoint

### GET `/api/v1/leaderboard`

Returns the top 10 users ranked by total reviews completed.

**Authentication:** None (public)

**Rate Limit:** Standard rate limits apply

### Response

```json
{
  "success": true,
  "code": 200,
  "message": "Success",
  "data": {
    "code": 200,
    "message": "Success",
    "users": [
      {
        "rank": 1,
        "uid": "google_abc123",
        "displayName": "Nguyen Van A",
        "photoURL": "https://lh3.googleusercontent.com/...",
        "totalReviews": 5420,
        "srsCards": 850,
        "roadmapDays": 120,
        "streakDays": 45
      },
      {
        "rank": 2,
        "uid": "google_def456",
        "displayName": "Tran Thi B",
        "photoURL": null,
        "totalReviews": 4100,
        "srsCards": 620,
        "roadmapDays": 95,
        "streakDays": 12
      }
    ],
    "status": "ok"
  }
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `rank` | integer | Position in leaderboard (1-based) |
| `uid` | string | User's unique identifier |
| `displayName` | string | User's display name (or "Anonymous") |
| `photoURL` | string/null | Google profile photo URL |
| `totalReviews` | integer | Total number of SRS reviews completed (primary ranking metric) |
| `srsCards` | integer | Total number of SRS cards created |
| `roadmapDays` | integer | Number of roadmap days completed |
| `streakDays` | integer | Current consecutive days with at least 1 review (resets if no review today/yesterday) |

### Ranking Logic

- **Primary sort:** `totalReviews` descending (users with more reviews rank higher)
- **Minimum requirement:** At least 1 review log to appear on leaderboard
- **Excluded:** Banned users (`is_banned = true`)
- **Limit:** Top 10 users

### Streak Calculation

A streak counts consecutive days (no gaps) where the user completed at least 1 review. The streak is only "current" if the most recent review day is today or yesterday. If the user skipped a day and hasn't reviewed today, their streak resets to 0.

Example:
- User reviewed on: Mar 5, Mar 4, Mar 3, Mar 1 → streak = 3 (Mar 3-5, gap before Mar 1)
- User reviewed on: Mar 3, Mar 2, Mar 1 (today is Mar 5) → streak = 0 (last review was 2 days ago)

## Caching

| Key | TTL | Job |
|-----|-----|-----|
| `leaderboard` | 10 minutes | `CacheLeaderboardJob` |

The job runs every 10 minutes via Sidekiq Cron. On cache miss, the controller triggers `CacheLeaderboardJob.perform_now` synchronously.

### Data Sources

| Metric | Table | Query |
|--------|-------|-------|
| totalReviews | `review_logs` | `GROUP BY user_id COUNT(*)` |
| srsCards | `srs_cards` | `GROUP BY user_id COUNT(*)` |
| roadmapDays | `roadmap_day_progresses` | `GROUP BY user_id COUNT(*)` |
| streakDays | `review_logs` | Consecutive distinct `DATE(reviewed_at)` per user |

## Files

| File | Description |
|------|-------------|
| `app/controllers/api/v1/leaderboard_controller.rb` | Public controller, reads from Redis cache |
| `app/jobs/cache_leaderboard_job.rb` | Background job: queries DB, computes rankings & streaks, writes to Redis |
| `config/routes.rb` | Route: `GET /api/v1/leaderboard` |
| `config/initializers/sidekiq.rb` | Cron schedule: every 10 minutes |
