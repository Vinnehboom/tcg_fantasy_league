class UserPolicy < ApplicationPolicy

  def initialize(user, other_user)
    @user = user
    @other_user = other_user
    super
  end

  def show?
    @user == @other_user || admin?
  end

end
