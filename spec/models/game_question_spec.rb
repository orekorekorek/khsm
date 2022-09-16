# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса,
# в идеале весь наш функционал (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do
  # задаем локальную переменную game_question, доступную во всех тестах этого сценария
  # она будет создана на фабрике заново для каждого блока it, где она вызывается
  let(:game_question) { FactoryBot.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  # группа тестов на игровое состояние объекта вопроса
  context 'game status' do
    # тест на правильную генерацию хэша с вариантами
    describe '#variants' do
      it 'should return variants of answers' do
        expect(game_question.variants).to eq({ 'a' => game_question.question.answer2,
                                               'b' => game_question.question.answer1,
                                               'c' => game_question.question.answer4,
                                               'd' => game_question.question.answer3 })
      end
    end

    describe '#text' do
      it 'should return correct text of question' do
        expect(game_question.text).to eq(game_question.question.text)
      end
    end

    describe '#level' do
      it 'should return correct level of question' do
        expect(game_question.level).to eq(game_question.question.level)
      end
    end

    describe '#answer_correct?' do
      it 'should return true if answer is correct' do
        # именно под буквой b в тесте мы спрятали указатель на верный ответ
        expect(game_question.answer_correct?('b')).to be true
      end

      it 'should return false if answer is wrong' do
        expect(game_question.answer_correct?('a')).to be false
      end
    end

    describe '#correct_answer_key' do
      it 'should return key of correct answer' do
        expect(game_question.correct_answer_key).to eq 'b'
      end
    end
  end

  # help_hash у нас имеет такой формат:
  # {
  #   fifty_fifty: ['a', 'b'], # При использовании подсказски остались варианты a и b
  #   audience_help: {'a' => 42, 'c' => 37 ...}, # Распределение голосов по вариантам a, b, c, d
  #   friend_call: 'Василий Петрович считает, что правильный ответ A'
  # }
  #

  describe '#help_hash' do
    it 'should return empty hash if help is not used' do
      expect(game_question.help_hash).to eq({})
    end

    it 'should save help hash correctly' do
      game_question.help_hash[:some_key1] = 'blabla1'
      game_question.help_hash['some_key2'] = 'blabla2'

      expect(game_question.save).to be_truthy

      gq = GameQuestion.find(game_question.id)

      expect(gq.help_hash).to eq({ some_key1: 'blabla1', 'some_key2' => 'blabla2' })
    end
  end

  context 'user helpers' do
    it 'should not contain audience help in help hash before help is used' do
      expect(game_question.help_hash).not_to include(:audience_help)
    end

    it 'should not contain friend call in help hash before help is used' do
      expect(game_question.help_hash).not_to include(:friend_call)
    end

    it 'should not contain fifity fifty help in help hash before help is used' do
      expect(game_question.help_hash).not_to include(:fifty_fifty)
    end

    describe '#add_fifty_fifty' do
      before { game_question.add_fifty_fifty }

      it 'should include fifty fifty help in help hash' do
        expect(game_question.help_hash).to include(:fifty_fifty)
      end

      it 'should contain correct answer' do
        expect(game_question.help_hash[:fifty_fifty]).to include('b')
      end

      it 'should contain 2 variants' do
        expect(game_question.help_hash[:fifty_fifty].size).to eq(2)
      end
    end

    describe '#add_friend_call' do
      before { game_question.add_friend_call }
      let(:friend_guess) { game_question.help_hash[:friend_call] }

      it 'should include friend call help in help hash' do
        expect(game_question.help_hash).to include(:friend_call)
      end

      it 'should contain string' do
        expect(friend_guess).to be_a String
      end

      it 'should contain guess of friend' do
        expect(friend_guess[-1].downcase).to match(/[abcd]/)
      end
    end

    describe '#add_audience_help' do
      before { game_question.add_audience_help }

      it 'should include audience help in help hash' do
        expect(game_question.help_hash).to include(:audience_help)
      end

      it 'should contain all variants of answers as keys' do
        ah = game_question.help_hash[:audience_help]
        expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
      end
    end
  end
end
