class SalaryDraftsController < ScopedGameController

  def index
    @salary_drafts = SalaryDraft
                     .includes(:tournament)
                     .where(tournament: { game: @game })
                     .where('tournament.starting_date > ?', DateTime.current)
                     .all.page(params[:page])
  end

  def show
    @salary_draft = SalaryDraft.find(params[:id])
  end

end
