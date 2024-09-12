class SalaryDraftsController < ScopedGameController

  def index
    @salary_drafts = @game.upcoming_drafts.page(params[:page])
  end

  def show
    @salary_draft = SalaryDraft.find(params[:id])
    return unless current_user

    @participation = current_user.participations.find_by(draft: @salary_draft)
  end

end
