# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/participatory_processes/test/factories"

FactoryBot.define do
  factory :questionnaire, class: Decidim::Forms::Questionnaire do
    title { Decidim::Faker::Localized.sentence }
    description do
      Decidim::Faker::Localized.wrapped("<p>", "</p>") do
        Decidim::Faker::Localized.sentence(4)
      end
    end
    tos { Decidim::Faker::Localized.sentence(4) }
    questionnaire_for { build(:participatory_process) }
  end

  factory :question, class: Decidim::Forms::Question do
    transient do
      answer_options []
    end

    body { Decidim::Faker::Localized.sentence }
    mandatory false
    position 0
    question_type { Decidim::Forms::Question::TYPES.first }
    questionnaire

    before(:create) do |question, evaluator|
      evaluator.answer_options.each do |answer_option|
        question.answer_options.build(
          body: answer_option["body"],
          free_text: answer_option["free_text"]
        )
      end
    end
  end

  factory :answer, class: Decidim::Forms::Answer do
    body { "hola" }
    questionnaire
    question { create(:question, questionnaire: questionnaire) }
    user { create(:user, organization: questionnaire.questionnaire_for.organization) }
  end

  factory :answer_option, class: Decidim::Forms::AnswerOption do
    body { Decidim::Faker::Localized.sentence }
  end

  factory :answer_choice, class: Decidim::Forms::AnswerChoice do
  end
end
