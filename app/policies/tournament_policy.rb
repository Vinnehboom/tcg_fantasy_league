class TournamentPolicy < ApplicationPolicy

  def initialize(user, tournament)
    @user = user
    @tournament = tournament
    super
  end

  def update?
    admin?
  end

  def update_results?
    admin?
  end

end
