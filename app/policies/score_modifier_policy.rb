class ScoreModifierPolicy < ApplicationPolicy

  def initialize(user, score_modifier)
    @user = user
    @score_modifier = score_modifier
    super
  end

  def new?
    admin?
  end

  def edit?
    admin?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

end
