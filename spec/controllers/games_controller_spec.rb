# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryGirl.create(:user) }
  # админ
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  describe '#create' do
    context 'when user is authorized' do
      before { sign_in user }

      context 'and tries to create first game' do
        before do
          generate_questions(15)
          post :create
          @game = assigns(:game)
        end

        it 'should not finish game' do
          expect(@game.finished?).to be false
        end

        it 'should assigns correct user to game' do
          expect(@game.user).to eq(user)
        end

        it 'should redirect to game page' do
          expect(response).to redirect_to(game_path(@game))
        end

        it 'should show a notice' do
          expect(flash[:notice]).to be
        end
      end

      context 'and tries to create second game' do
        it 'should not create second game' do
          expect(game_w_questions.finished?).to be false

          expect { post :create }.to change(Game, :count).by(0)

          game = assigns(:game)
          expect(game).to be_nil

          expect(response).to redirect_to(game_path(game_w_questions))
          expect(flash[:alert]).to be
        end
      end
    end

    context 'when user in not autorized' do
      before { post :create }

      it 'should return response status not 200 OK' do
        expect(response.status).to eq(302)
      end

      it 'should redirect to login page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should show an alert' do
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#show' do
    context 'when user is not authorized' do
      before { get :show, id: game_w_questions.id }

      it 'should return 302 response status' do
        expect(response.status).to eq(302)
      end

      it 'should redirect anonimous user to login page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should show an alert' do
        expect(flash[:alert]).to be
      end
    end

    context 'when user is signed in' do
      before do
        sign_in user
        get :show, id: game_w_questions.id
      end

      context 'and game belongs to user' do
        it 'should assigns correct user to game' do
          game = assigns(:game)
          expect(game.user).to eq(user)
        end

        it 'should not finish game' do
          expect(game_w_questions.finished?).to be false
        end

        it 'should return 200 OK response status' do
          expect(response.status).to eq(200)
        end

        it 'should render show template' do
          expect(response).to render_template('show')
        end
      end

      context 'and game does not belong to user' do
        let(:game_w_questions) { FactoryGirl.create(:game_with_questions) }

        it 'should return not 200 OK response status' do
          expect(response.status).not_to eq(200)
        end

        it 'should redirect to main page' do
          expect(response).to redirect_to(root_path)
        end

        it 'should show an alert' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#answer' do
    context 'when user is authorized' do
      before { sign_in user }

      context 'and answer is correct' do
        before do
          put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
          @game = assigns(:game)
        end

        it 'should not finish game' do
          expect(@game.finished?).to be false
        end

        it 'should increase level' do
          expect(@game.current_level).to be > 0
        end

        it 'should redirect to game page' do
          expect(response).to redirect_to(game_path(@game))
        end

        it 'should not show flash' do
          expect(flash.empty?).to be true
        end
      end

      context 'and answer is wrong' do
        before do
          put :answer, id: game_w_questions.id, letter: 'a'
          @game = assigns(:game)
        end

        it 'should finish game' do
          expect(@game.finished?).to be true
        end

        it 'should show flash' do
          expect(flash.alert).to be
        end

        it 'should redirect to user page' do
          expect(response).to redirect_to(user_path(user))
        end

        it 'should change game status to fail' do
          expect(@game.status).to eq(:fail)
        end
      end
    end

    context 'when user in not autorized' do
      before { put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }

      it 'should return response status not 200 OK' do
        expect(response.status).to eq(302)
      end

      it 'should redirect to login page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should show an alert' do
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#help' do
    context 'when user is authorized' do
      before { sign_in user }

      context 'and help is not used' do
        it 'should not contain audience help in help hash before help is used' do
          expect(game_w_questions.current_game_question.help_hash).not_to include(:audience_help)
        end

        it 'should not contain fifty fifty help in help hash before help used' do
          expect(game_w_questions.current_game_question.help_hash).not_to include(:fifty_fifty)
        end

        it 'should not contain friend call help in help hash before help used' do
          expect(game_w_questions.current_game_question.help_hash).not_to include(:friend_call)
        end

        it 'should not have used audience help' do
          expect(game_w_questions.audience_help_used).to be false
        end

        it 'should not have used fifty fifty' do
          expect(game_w_questions.fifty_fifty_used).to be false
        end

        it 'should not have used friend call' do
          expect(game_w_questions.friend_call_used).to be false
        end
      end

      context 'and fifty fifty help is used' do
        before do
          put :help, id: game_w_questions.id, help_type: :fifty_fifty
          @game = assigns(:game)
        end

        let(:correct_answer) { game_w_questions.current_game_question.correct_answer_key }

        it 'should not finish game' do
          expect(@game.finished?).to be false
        end

        it 'should have used help' do
          expect(@game.fifty_fifty_used).to be true
        end

        it 'should add help to help hash' do
          expect(@game.current_game_question.help_hash[:fifty_fifty]).to be
        end

        it 'should contain 2 variants of answers' do
          expect(@game.current_game_question.help_hash[:fifty_fifty].size).to eq(2)
        end

        it 'should contain correct answer' do
          expect(@game.current_game_question.help_hash[:fifty_fifty]).to include(correct_answer)
        end

        it 'should redirect to game page' do
          expect(response).to redirect_to(game_path(@game))
        end
      end

      context 'and audience help is used' do
        before do
          put :help, id: game_w_questions.id, help_type: :audience_help
          @game = assigns(:game)
        end

        it 'should not finish game' do
          expect(@game.finished?).to be false
        end

        it 'should have used help' do
          expect(@game.audience_help_used).to be true
        end

        it 'should add help to help hash' do
          expect(@game.current_game_question.help_hash[:audience_help]).to be
        end

        it 'should contain keys of answers in help hash' do
          expect(@game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
        end

        it 'should redirect to game page' do
          expect(response).to redirect_to(game_path(@game))
        end
      end

      context 'and friend call is used' do
        before do
          put :help, id: game_w_questions.id, help_type: :friend_call
          @game = assigns(:game)
        end

        let(:help_hash) { @game.current_game_question.help_hash }

        it 'should not finish game' do
          expect(@game.finished?).to be false
        end

        it 'should have used friend call' do
          expect(@game.friend_call_used).to be true
        end

        it 'should add friend call to help hash' do
          expect(help_hash).to include(:friend_call)
        end

        it 'should contain string with friend guess in help hash' do
          expect(help_hash[:friend_call]).to be_a String
        end

        it 'should contain variant of answer in friend guess' do
          expect(help_hash[:friend_call][-1].downcase).to match(/[abcd]/)
        end

        it 'should redirect to game page' do
          expect(response).to redirect_to(game_path(@game))
        end
      end
    end

    context 'when user in not autorized' do
      before { put :help, id: game_w_questions.id, help_type: :audience_help }

      it 'should return response status not 200 OK' do
        expect(response.status).to eq(302)
      end

      it 'should redirect to login page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should show an alert' do
        expect(flash[:alert]).to be
      end
    end
  end

  describe '#take_money' do
    context 'when user is authorized' do
      before do
        sign_in user
        game_w_questions.update_attribute(:current_level, 2)
        put :take_money, id: game_w_questions.id
        @game = assigns(:game)
        user.reload
      end

      it 'should finish game' do
        expect(@game.finished?).to be true
      end

      it 'should assign 200 to prize' do
        expect(@game.prize).to eq(200)
      end

      it 'should assign przie to user balance' do
        expect(user.balance).to eq(200)
      end

      it 'should redirect to user page' do
        expect(response).to redirect_to(user_path(user))
      end

      it 'should show warning' do
        expect(flash[:warning]).to be
      end
    end

    context 'when user in not autorized' do
      before { put :take_money, id: game_w_questions.id }

      it 'should return response status not 200 OK' do
        expect(response.status).to eq(302)
      end

      it 'should redirect to login page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'should show an alert' do
        expect(flash[:alert]).to be
      end
    end
  end
end
