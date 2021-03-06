# == Schema Information
#
# Table name: projects
#
#  id            :integer          not null, primary key
#  price_of_hour :integer
#  name          :string
#  owner_id      :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  data          :hstore
#

require 'rails_helper'

RSpec.describe Project, type: :model do
  let(:project) { FactoryGirl.create :project }

  context "FactoryGirl" do
    it { expect(project).not_to be_new_record }
    it { FactoryGirl.create :project, :with_project_user }
    it { FactoryGirl.create :project, :with_other_user }
    it { FactoryGirl.create :project, :with_slack_channel }
    it { FactoryGirl.create :project, :with_records }
    it { FactoryGirl.create :project_for_slack_notify }
    it { FactoryGirl.create :project_has_members }
    it { FactoryGirl.create :project_has_records }
    it { attributes_for :project_for_update, :setting }
    it { attributes_for :project_for_update, :project_users }
  end

  describe "order by project_user sort" do
    let!(:user) { FactoryGirl.create :user }
    let!(:project_user1) { FactoryGirl.create :project_user, user: user }
    let!(:project_user2) { FactoryGirl.create :project_user, user: user }

    before { project_user1.update_attribute(:sort, 2) }
    before { project_user2.update_attribute(:sort, 1) }

    context "sort" do
      it { expect(user.projects[0]).to eq(project_user2.project) }
      it { expect(user.projects[1]).to eq(project_user1.project) }
    end
  end
end
