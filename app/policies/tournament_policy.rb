class TournamentPolicy < ApplicationPolicy

  def initialize(user, tournament)
    @user = user
    @tournament = tournament
    super
  end

  def set_results_source_id?
    admin?
  end

end
