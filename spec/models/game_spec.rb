require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { FactoryGirl.create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game_for_user! new correct game' do
      generate_questions(60)

      game = nil
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15)
      )

      # проверяю статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяю корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # тесты на основную игровую логику
  context 'game mechanics' do
    it 'answer correct continues' do
      q = game_w_questions.current_game_question
      level = game_w_questions.current_level
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level +1)

      expect(game_w_questions.previous_game_question).to eq q
      expect(game_w_questions.current_game_question).not_to eq q

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end
  end

  # тесты на метод take_money
  context '#take_money' do

    it '#take prizes' do

      prizes = [
        100, 200, 300, 500, 1000,
        2000, 4000, 8000, 16000, 32000,
        64000, 125000, 250000, 500000
      ]


      2.times do
        q = game_w_questions.current_game_question
        game_w_questions.answer_current_question!(q.correct_answer_key)
      end

      game_w_questions.take_money!

      expect(game_w_questions.prize).to eq prizes[1]

    end

    # тест на миллион
    it 'prize on million' do
      15.times do
        q = game_w_questions.current_game_question
        game_w_questions.answer_current_question!(q.correct_answer_key)
      end

      expect(game_w_questions.finished?).to be_truthy

      expect(user.balance).to eq 1000000

      expect(game_w_questions.status). to eq :won # метод .status возвращает победу

    end
  end

  # проверка метода статус
  context '#status' do

    it '#status :fails' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(!q.correct_answer_key)

      expect(game_w_questions.status).to eq :fail
    end

    it '#status :money' do

      game_w_questions.current_game_question

      game_w_questions.take_money!

      expect(game_w_questions.status).to eq :money

    end

  end

  context '#status :timeout' do

    before(:each) do
      game_w_questions.finished_at = Time.now
    end

    it 'timeout' do
      game_w_questions.created_at = 36.minutes.ago

      game_w_questions.is_failed = true

      expect(game_w_questions.status).to eq :timeout
    end

  end

end