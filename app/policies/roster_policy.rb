class RosterPolicy < ApplicationPolicy

  def initialize(user, roster)
    @user = user
    @roster = roster
    super
  end

  def new?
    @user.rosters.where(participation: @roster.participation).blank?
  end

  def show?
    admin? || @roster.user == @user
  end

  def edit?
    @roster.participation.status == 'created' && (admin? || @roster.user == @user)
  end

  def update?
    @roster.participation.status == 'created' && (admin? || @roster.user == @user)
  end

  def create?
    @roster.user == @user && @user.rosters.where(participation: @roster.participation).blank?
  end

  def destroy?
    @roster.participation.status == 'created' && (admin? || @roster.user == @user)
  end

end
