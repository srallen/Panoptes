module TranslatedContent
  extend ActiveSupport::Concern

  included do
    has_paper_trail skip: [:langauge]
    validates :language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}
    belongs_to translated_for
  end

  module ClassMethods
    def translated_for
      name[0..-8].downcase.to_sym
    end
  end
end