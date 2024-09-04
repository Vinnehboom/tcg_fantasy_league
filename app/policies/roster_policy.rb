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
    admin? || @roster.user == @user
  end

  def update?
    admin? || @roster.user == @user
  end

  def create?
    @roster.user == @user && @user.rosters.where(participation: @roster.participation).blank?
  end

  def destroy?
    admin? || @roster.user == @user
  end

end
