require 'rails_helper'

RSpec.feature 'USER views alien profile', type: :feature do
  let(:profile_owner) { FactoryBot.create(:user, name: 'Project Pat') }
  let(:profile_visitor) { FactoryBot.create(:user, name: 'DJ Paul') }

  let!(:games) do
    [
      FactoryBot.create(:game,
                        user: profile_owner,
                        id: 1337,
                        created_at: Time.parse('2017.10.09, 10:00'),
                        current_level: 10,
                        prize: 1000),

      FactoryBot.create(:game,
                        user: profile_owner,
                        id: 228,
                        created_at: Time.parse('2017.10.09, 13:00'),
                        finished_at: Time.parse('2017.10.09, 14:00'),
                        is_failed: true)
    ]
  end

  before { login_as profile_visitor }

  feature 'successfully' do
    before { visit '/users/1' }

    it 'should show profile owner name' do
      expect(page).to have_content 'Project Pat'
    end

    it 'should not show link to edit user registration page' do
      expect(page).not_to have_content 'Сменить имя и пароль'
    end

    it 'should show game ids' do
      expect(page).to have_content '1337'
      expect(page).to have_content '228'
    end

    it 'should show dates of start games' do
      expect(page).to have_content '9 окт., 13:00'
      expect(page).to have_content '9 окт., 16:00'
    end

    it 'should show number of current question' do
      expect(page).to have_content '10'
    end

    it 'should show prize' do
      expect(page).to have_content '1 000 ₽'
    end

    it 'should show statuses of games' do
      expect(page).to have_content 'в процессе'
      expect(page).to have_content 'время'
    end
  end
end
