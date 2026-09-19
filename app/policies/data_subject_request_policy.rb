class DataSubjectRequestPolicy < ApplicationPolicy

  def update?
    admin? && record.queued?
  end

end
