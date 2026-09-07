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
      tournament.starting_date > Date.current &&
      meets_draft_age_requirement?
  end

  def update?
    @participation.status == 'created' && (admin? || @participation.user == @user)
  end

  def destroy?
    admin? || @participation.user == @user
  end

  private

  def meets_draft_age_requirement?
    return true unless @participation.draft.requires_18_plus?

    @user.country.present? && @user.date_of_birth.present? &&
      @user.age >= AgeGate::PRIZE_DRAFT_MINIMUM_AGE
  end

end
