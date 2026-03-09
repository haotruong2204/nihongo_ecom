namespace :revenue do
  desc "Sync revenue records from existing premium users (run once to backfill historical data)"
  task sync: :environment do
    users = User.where.not(premium_until: nil)
    count = 0
    skipped = 0

    users.each do |user|
      if RevenueRecord.exists?(user: user)
        skipped += 1
        next
      end

      # Dùng updated_at làm mốc thời điểm upgrade để tính plan_type chính xác
      plan_type = RevenueRecord.plan_type_from_until(user.premium_until, user.updated_at)
      amount = plan_type == "yearly" ? RevenueRecord::YEARLY_PRICE : RevenueRecord::MONTHLY_PRICE

      # Use user's updated_at as proxy for when the upgrade happened
      RevenueRecord.create!(
        user:          user,
        amount:        amount,
        plan_type:     plan_type,
        premium_until: user.premium_until,
        created_at:    user.updated_at,
        updated_at:    user.updated_at
      )
      count += 1
    end

    puts "Done. Synced: #{count}, Skipped (already exists): #{skipped}"
  end
end
