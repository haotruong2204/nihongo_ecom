# frozen_string_literal: true

class Api::V1::Users::UserDevicesController < Api::V1::UserBaseController
  def index
    devices = current_user.user_devices.recent
    current_device_id = request.headers["X-Device-ID"].presence

    render json: {
      data: UserDeviceSerializer.new(devices).serializable_hash[:data],
      current_device_id: current_device_id
    }
  end

  def destroy
    device = current_user.user_devices.find(params[:id])
    device.destroy!
    render json: { message: "Đã xóa thiết bị" }
  end
end
