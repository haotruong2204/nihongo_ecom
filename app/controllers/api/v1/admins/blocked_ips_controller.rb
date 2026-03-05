# frozen_string_literal: true

class Api::V1::Admins::BlockedIpsController < Api::V1::BaseController
  include Pagy::Backend

  def index
    q = BlockedIp.ransack(params[:q])
    pagy, ips = pagy(q.result.recent, limit: params[:per_page] || 20)

    response_success({
                       code: 200,
                       message: I18n.t("api.common.success"),
                       resource: BlockedIpSerializer.new(ips).serializable_hash,
                       pagy: pagy_metadata(pagy),
                       status: :ok
                     })
  end

  def create
    ip = BlockedIp.new(blocked_ip_params)
    ip.blocked_by = current_admin

    if ip.save
      banned_users = ban_associated_users(ip.ip_address)
      message = "IP #{ip.ip_address} has been blocked."
      message += " #{banned_users.size} user(s) banned: #{banned_users.join(', ')}" if banned_users.any?

      response_success({
                         code: 201,
                         message: message,
                         resource: BlockedIpSerializer.new(ip).serializable_hash,
                         status: :created
                       })
    else
      unprocessable_entity(ip)
    end
  end

  def destroy
    ip = BlockedIp.find(params[:id])
    unbanned_users = unban_associated_users(ip.ip_address)
    ip.destroy!

    message = "IP #{ip.ip_address} has been unblocked."
    message += " #{unbanned_users.size} user(s) unbanned: #{unbanned_users.join(', ')}" if unbanned_users.any?

    response_success({
                       code: 200,
                       message: message,
                       status: :ok
                     })
  rescue ActiveRecord::RecordNotFound
    not_found
  end

  private

  def ban_associated_users(ip_address)
    logs = DevtoolsLog.where(ip_address: ip_address).where.not(user_id: nil).includes(:user)
    banned = []

    logs.each do |log|
      user = log.user
      next if user.nil? || user.banned?

      user.update!(is_banned: true, banned_reason: "IP #{ip_address} blocked (DevTools)")
      user.update!(jti: SecureRandom.uuid)
      banned << user.email
    end

    banned
  end

  def unban_associated_users(ip_address)
    logs = DevtoolsLog.where(ip_address: ip_address).where.not(user_id: nil).includes(:user)
    unbanned = []

    logs.each do |log|
      user = log.user
      next if user.nil? || !user.banned?

      user.update!(is_banned: false, banned_reason: nil)
      unbanned << user.email
    end

    unbanned
  end

  def blocked_ip_params
    params.require(:blocked_ip).permit(:ip_address, :reason)
  end

  def pagy_metadata pagy
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit
    }
  end
end
