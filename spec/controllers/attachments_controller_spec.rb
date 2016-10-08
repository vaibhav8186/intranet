require 'spec_helper'

describe AttachmentsController do
  let(:public_doc) { FactoryGirl.create :attachment, is_visible_to_all: true }

  before(:each) do
    @admin = FactoryGirl.create(:user, email: 'admin@joshsoftware.com', role: 'Admin')
    sign_in @admin
  end

  describe '#index' do
    it 'renders index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe "#update" do

    before(:each) do
      @attachment = FactoryGirl.create(:attachment, is_visible_to_all: true)
    end

    it 'will make is_visible false' do
      post :update, {id: @attachment.id, "attachment" => {is_visible_to_all: false}}
      expect(@attachment.reload.is_visible_to_all).to eq(false)
    end

    it 'will make is_visible true' do
      post :update, {id: @attachment.id, "attachment" => {is_visible_to_all: true}}
      expect(@attachment.reload.is_visible_to_all).to eq(true)
    end
  end

  describe '#download_document' do
    context 'document is visible to all' do
      it 'should return the document' do
        get :download_document, { id: public_doc.id }
        expect(response).to be_success
      end
    end
  end
end
