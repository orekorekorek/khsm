require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:user) { FactoryGirl.create(:user, name: 'Example') }

  before do
    assign(:user, user)
    assign(:games, [
             FactoryGirl.build_stubbed(:game,
                                       id: 1337,
                                       created_at: Time.parse('2017.10.09, 13:00'),
                                       current_level: 10, prize: 1000),

             FactoryGirl.build_stubbed(:game,
                                       id: 1337,
                                       created_at: Time.parse('2017.10.09, 13:00'),
                                       current_level: 10, prize: 1000)
           ])
  end

  it 'should render user name' do
    render
    expect(rendered).to match 'Example'
  end

  it 'should render game id' do
    stub_template 'users/_game.html.erb' => '<%= game.id %></br>'
    render
    expect(rendered).to match '1337'
  end

  it 'should render game date' do
    stub_template 'users/_game.html.erb' => '<%= l game.created_at, format: :short %></br>'
    render
    expect(rendered).to match '09 окт., 16:00'
  end

  it 'should render current game level' do
    stub_template 'users/_game.html.erb' => '<%= game.current_level %></br>'
    render
    expect(rendered).to match '10'
  end

  it 'should render game id' do
    stub_template 'users/_game.html.erb' => '<%= number_to_currency game.prize %></br>'
    render
    expect(rendered).to match '1 000 ₽'
  end

  context 'when user is owner of viewed user account' do
    before { sign_in user }

    it 'should render link to edit user registration page' do
      render
      expect(rendered).to match 'Сменить имя и пароль'
    end
  end

  context 'when user is not owner of viewed user account' do
    context 'and user is authorized' do
      let(:another_user) { FactoryGirl.create(:user, name: 'AnotherExample') }

      before { sign_in another_user }

      it 'should not render link to edit user registration page' do
        render
        expect(rendered).not_to match 'Сменить имя и пароль'
      end
    end

    context 'and user is unauthorized' do
      it 'should not render link to edit user registration page' do
        render
        expect(rendered).not_to match 'Сменить имя и пароль'
      end
    end
  end
end
