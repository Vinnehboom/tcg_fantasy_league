class SeasonPolicy < ApplicationPolicy

  def new?
    admin?
  end

  def create?
    admin?
  end

end
