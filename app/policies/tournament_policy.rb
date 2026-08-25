class TournamentPolicy < ApplicationPolicy

  def initialize(user, tournament)
    @user = user
    @tournament = tournament
    super
  end

  def update?
    admin?
  end

  def trigger_results_import?
    admin?
  end

end
