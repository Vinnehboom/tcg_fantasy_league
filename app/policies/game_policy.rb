class GamePolicy < ApplicationPolicy

  def initialize(user, game)
    @user = user
    @game = game
    super
  end

  def trigger_import?
    admin?
  end

end
