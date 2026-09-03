class Game < ApplicationRecord

  include GameRegistry

  # Runs synchronously inside an admin web request, so a tight timeout and
  # no retries — RetryPolicy's defaults could block a web worker for 30-60s+.
  PTCG_RESULTS_VERIFIER = lambda do |tournament_id|
    ExternalData::Pokemon::Tcg::LabsTournament.call(
      tournament_id:,
      retry_policy: ExternalData::RetryPolicy.new(timeout: 3, retry_delays: [])
    )
  end

  PTCG_ADAPTER = ->(game:) { ExternalData::Pokemon::Tcg::Adapter.new(game:) }

  register :ptcg, id: 'PTCG', adapter: PTCG_ADAPTER, results_verifier: PTCG_RESULTS_VERIFIER,
                  results_import_job: ExternalData::ImportResultsJob

  has_many :players, dependent: :nullify
  has_many :tournaments, dependent: :nullify
  has_many :salary_drafts, through: :tournaments
  has_many :external_requests, dependent: :restrict_with_error
  has_many :seasons, dependent: :destroy
  has_one :default_setting, as: :settingable, class_name: 'Setting', dependent: :destroy

  validates :name, presence: true
  validates :base_uri, presence: true

  def upcoming_drafts
    salary_drafts.upcoming
  end

  # Excludes internal (default/backstop) seasons — this is "the season a
  # user would recognize," not "a season to read scoring config from."
  # Without the exclusion, a genuinely seasonless game (Riftbound) with
  # only its internal default row would start showing a spurious
  # `?season=default` on every player's external URL the moment that row
  # exists, and a game with both a real season and its now-superseded
  # internal row would raise (two candidates instead of one) rather than
  # resolving to the real one.
  def current_season(on: Date.current)
    @current_season_by_date ||= {}
    return @current_season_by_date[on] if @current_season_by_date.key?(on)

    @current_season_by_date[on] = begin
      seasons.covering(on).where(internal: false).sole
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end

end
