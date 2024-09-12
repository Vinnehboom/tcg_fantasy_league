class UserPolicy < ApplicationPolicy

  def initialize(user, other_user)
    @user = user
    @other_user = other_user
    super
  end

  def show?
    true
  end

  def can_see_email?
    @user == @other_user || admin?
  end

end
