# frozen_string_literal: true

class Api::V1::Users::PageViewsController < Api::V1::UserBaseController
  def create
    url = params[:url].to_s.strip
    return head :bad_request if url.blank?

    page_view = current_user.page_views.find_or_initialize_by(url: url)
    page_view.view_count = page_view.persisted? ? page_view.view_count + 1 : 1
    page_view.last_visited_at = Time.current
    page_view.save!

    head :no_content
  end
end
