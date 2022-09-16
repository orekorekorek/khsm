# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { FactoryBot.create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # генерим 60 вопросов с 4х запасом по полю level,
      # чтобы проверить работу RANDOM при создании игры
      generate_questions(60)

      game = nil
      # создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and( # проверка: Game.count изменился на 1 (создали в базе 1 игру)
        change(GameQuestion, :count).by(15).and( # GameQuestion.count +15
          change(Question, :count).by(0) # Game.count не должен измениться
        )
      )
      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # тесты на основную игровую логику
  context 'game mechanics' do
    describe '#answer_current_question!' do
      context 'when answer is correct' do
        let(:question) { game_w_questions.current_game_question }
        let(:correct_answer_key) { question.correct_answer_key }

        context 'and question is not last' do
          let!(:level) { game_w_questions.current_level }
          let!(:answer_question) { game_w_questions.answer_current_question!(correct_answer_key) }

          it 'should increase level by 1' do
            expect(game_w_questions.current_level).to eq(level + 1)
          end

          it 'shouldn`t finish game' do
            expect(game_w_questions.finished?).to be false
          end

          it 'should should keep game in progress' do
            expect(game_w_questions.status).to eq(:in_progress)
          end

          it 'should current question to become previous' do
            expect(game_w_questions.previous_game_question).to eq(question)
          end

          it 'should previous question not to become current' do
            expect(game_w_questions.current_game_question).not_to eq(question)
          end
        end

        context 'and question is last' do
          let!(:level) { game_w_questions.current_level = 14 }
          let!(:answer_question) { game_w_questions.answer_current_question!(correct_answer_key) }

          it 'should finish game' do
            expect(game_w_questions.finished?).to be true
          end

          it 'should game status to become won' do
            expect(game_w_questions.status).to eq(:won)
          end

          it 'should assign the biggiest prize' do
            expect(game_w_questions.prize).to eq(1_000_000)
          end
        end

        context 'and time is over' do
          let!(:time_is_over) { game_w_questions.created_at = 1.hour.ago }
          let!(:answer_question) { game_w_questions.answer_current_question!(correct_answer_key) }

          it 'should finish game' do
            expect(game_w_questions.finished?).to be true
          end

          it 'should game status to become timeout' do
            expect(game_w_questions.status).to eq(:timeout)
          end
        end
      end

      context 'when answer is wrong' do
        let!(:wrong_answer) { game_w_questions.answer_current_question!(:a) }

        it 'should finish game' do
          expect(game_w_questions.finished?).to be true
        end

        it 'should game status to become fail' do
          expect(game_w_questions.status).to eq(:fail)
        end
      end
    end

    describe '#take_money!' do
      before(:each) do
        q = game_w_questions.current_game_question
        game_w_questions.answer_current_question!(q.correct_answer_key)
        game_w_questions.take_money!
      end

      let(:prize) { game_w_questions.prize }

      it 'should increase the prize' do
        expect(prize).to be > 0
      end

      it 'should change game status to :money' do
        expect(game_w_questions.status).to eq :money
      end

      it 'should finish game' do
        expect(game_w_questions.finished?).to be true
      end

      it 'should increase user balance by prize amount' do
        expect(user.balance).to eq prize
      end
    end
  end

  # группа тестов на проверку статуса игры
  describe '#status' do
    # перед каждым тестом "завершаем игру"
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be true
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  describe '#current_game_question' do
    it 'should return current game question' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions.first)
    end
  end

  describe '#previous_level' do
    it 'should return -1 for new game' do
      expect(game_w_questions.previous_level).to eq(-1)
    end
  end
end
