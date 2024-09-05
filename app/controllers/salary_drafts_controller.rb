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
    return unless current_user

    @participation = current_user.participations.find_by(draft: @salary_draft)
  end

  def new
    @salary_draft = SalaryDraft.new
    authorize @salary_draft
    @tournaments = @game.tournaments.upcoming
  end

  def edit
    @salary_draft = SalaryDraft.find(params[:id])
    authorize @salary_draft
    @tournaments = @game.tournaments.upcoming
  end

  def create
    @salary_draft = SalaryDraft.new(salary_draft_params)
    authorize @salary_draft
    if @salary_draft.save
      redirect_to [@game, @salary_draft], notice: t('.success')
    else
      flash[:error] = t('.failed')
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @salary_draft = SalaryDraft.find(params[:id])
    authorize @salary_draft
    if @salary_draft.update(salary_draft_params)
      redirect_to [@game, @salary_draft], notice: t('.success')
    else
      flash[:error] = t('.failed')
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @salary_draft = SalaryDraft.find(params[:id])
    authorize @salary_draft
    if @salary_draft.destroy
      redirect_to game_salary_drafts_path(game: @game), notice: t('.success')
    else
      flash[:error] = t('.failed')
      redirect_to [@game, @salary_draft]
    end
  end

  private

  def salary_draft_params
    params.require(:salary_draft).permit(:roster_size, :price_cap, :tournament_id)
  end

end
