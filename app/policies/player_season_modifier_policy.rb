class PlayerSeasonModifierPolicy < ApplicationPolicy

  def initialize(user, player_season_modifier)
    @user = user
    @player_season_modifier = player_season_modifier
    super
  end

  def create?
    admin?
  end

  def destroy?
    admin?
  end

end
