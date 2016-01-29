require 'rails_helper'

describe ProjectUpdateSettingContext do
  let(:user) { FactoryGirl.create :user }
  let(:user1) { FactoryGirl.create :user }
  let(:data) { data_for(:update_project_setting) }
  before { project_created!(user) }

  it "success" do
    expect {
      described_class.new(user, @project).perform(data)
    }.to change { @project.reload.name }
    expect(@project.price_of_hour).to eq(data[:price_of_hour])
  end

  it "not owner" do
    expect {
      described_class.new(user1, @project).perform(data)
    }.not_to change { @project.reload.name }
    expect(@project.price_of_hour).not_to eq(data[:price_of_hour])
  end
end