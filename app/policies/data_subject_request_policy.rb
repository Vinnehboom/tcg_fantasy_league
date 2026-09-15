class DataSubjectRequestPolicy < ApplicationPolicy

  def mark_actioned?
    admin? && record.queued?
  end

end
