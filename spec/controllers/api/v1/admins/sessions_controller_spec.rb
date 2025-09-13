require "rails_helper"

RSpec.describe Api::V1::Admins::SessionsController, type: :controller do
  let(:admin) { create(:admin) }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:admin]
  end

  describe 'POST #create' do
    
  end

  describe 'DELETE #destroy' do
    before do
      sign_in admin
    end
  end
end
