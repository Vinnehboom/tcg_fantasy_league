class Game < ApplicationRecord

  include GameRegistry

  # The verifier runs synchronously inside an admin web request (a Puma
  # thread), so it uses a tight timeout and no retries instead of
  # RetryPolicy's background-job-oriented defaults, which could otherwise
  # block a web worker for 30-60s+.
  PTCG_RESULTS_VERIFIER = lambda do |tournament_id|
    ExternalData::Pokemon::Tcg::LabsTournament.call(
      tournament_id:,
      retry_policy: ExternalData::RetryPolicy.new(timeout: 3, retry_delays: [])
    )
  end

  register :ptcg, id: 'PTCG', results_verifier: PTCG_RESULTS_VERIFIER

  validates :name, presence: true
  validates :base_uri, presence: true

  has_many :players, dependent: :nullify
  has_many :tournaments, dependent: :nullify
  has_many :salary_drafts, through: :tournaments
  has_many :external_requests, dependent: :restrict_with_error
  has_many :seasons, dependent: :destroy
  has_many :settings, through: :seasons

  def upcoming_drafts
    salary_drafts.upcoming
  end

  def current_season(on: Date.current)
    @current_season_by_date ||= {}
    return @current_season_by_date[on] if @current_season_by_date.key?(on)

    @current_season_by_date[on] = begin
      seasons.covering(on).sole
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end

end
