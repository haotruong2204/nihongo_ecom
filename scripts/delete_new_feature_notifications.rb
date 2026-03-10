# Script xóa thông báo chào mừng từ 1/3/2026 trở về trước
# Chạy: bundle exec rails runner scripts/delete_new_feature_notifications.rb

cutoff = Time.zone.local(2026, 3, 1).end_of_day

count = UserNotification.where(notification_type: "welcome").where("created_at <= ?", cutoff).count

if count == 0
  puts "Không có thông báo nào cần xóa."
else
  UserNotification.where(notification_type: "welcome").where("created_at <= ?", cutoff).delete_all
  puts "Đã xóa #{count} thông báo chào mừng từ 1/3/2026 trở về trước."
end
