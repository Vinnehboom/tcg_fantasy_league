class ParticipationPolicy < ApplicationPolicy

  def initialize(user, participation)
    @user = user
    @participation = participation
    super
  end

  def show?
    admin? || @participation.user == @user
  end

  def create?
    tournament = Tournament.find_by(id: @participation.draft.tournament_id)
    @participation.user == @user &&
      @user.participations.where(draft: @participation.draft).blank? &&
      tournament &&
      tournament.starting_date > Date.current
  end

  def update?
    @participation.status == 'created' && (admin? || @participation.user == @user)
  end

  def destroy?
    admin? || @participation.user == @user
  end

end
