# frozen_string_literal: true

class WebPushService
  VAPID_SUBJECT = "mailto:#{ENV.fetch('VAPID_CONTACT_EMAIL', 'admin@nhaikanji.com')}"

  def self.send_to_user(user, payload)
    subscriptions = user.push_subscriptions
    return if subscriptions.empty?

    message = payload.to_json

    subscriptions.each do |sub|
      send_to_subscription(sub, message)
    end
  end

  def self.send_to_subscription(subscription, message)
    Webpush.payload_send(
      message: message,
      endpoint: subscription.endpoint,
      p256dh: subscription.p256dh_key,
      auth: subscription.auth_key,
      vapid: {
        subject: VAPID_SUBJECT,
        public_key: ENV["VAPID_PUBLIC_KEY"],
        private_key: ENV["VAPID_PRIVATE_KEY"]
      },
      ttl: 60 * 60 * 24 # 24 giờ
    )
  rescue Webpush::ExpiredSubscription, Webpush::InvalidSubscription
    subscription.destroy
  rescue => e
    Rails.logger.error("[WebPush] Error: #{e.message}")
  end
end
