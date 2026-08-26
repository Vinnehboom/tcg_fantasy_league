class TournamentPolicy < ApplicationPolicy

  def initialize(user, tournament)
    @user = user
    @tournament = tournament
    super
  end

  def update?
    admin?
  end

end
