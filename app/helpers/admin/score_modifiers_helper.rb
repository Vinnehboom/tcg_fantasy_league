module Admin

  module ScoreModifiersHelper

    def score_modifier_name_label(name)
      I18n.t(name, scope: %i[activerecord enums score_modifier name])
    end

  end

end
