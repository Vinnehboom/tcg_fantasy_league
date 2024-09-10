class SalaryDraftPolicy < ApplicationPolicy

  def initialize(user, salary_draft)
    @user = user
    @salary_draft = salary_draft
    super
  end

  def new?
    admin?
  end

  def edit?
    admin?
  end

  def update?
    admin?
  end

  def create?
    admin?
  end

  def complete?
    admin? && Date.current > @salary_draft.tournament.starting_date
  end

  def destroy?
    admin?
  end

end
