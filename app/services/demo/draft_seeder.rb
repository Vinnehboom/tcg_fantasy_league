module Demo

  class DraftSeeder < ApplicationService

    include ProductionGuard

    ROSTER_SIZE = 5
    PRICE_CAP_HEADROOM = 10.0
    PARTICIPANT_COUNT = 5
    DEMO_USERNAME = 'demo'.freeze
    DEMO_EMAIL = 'demo@example.com'.freeze
    DEMO_PASSWORD = 'demopass'.freeze
    ADMIN_USERNAME = 'admin'.freeze
    ADMIN_EMAIL = 'admin@example.com'.freeze
    ADMIN_PASSWORD = 'adminpass'.freeze
    PARTICIPANT_PASSWORD = 'demoplayerpass'.freeze

    def call
      raise_outside_the_sandbox!
      demo_user
      admin_user
      ::Tournament.find_each { |tournament| seed_draft(tournament) }
    end

    private

    def demo_user
      @demo_user ||= ::User.find_by(username: DEMO_USERNAME) ||
                     FactoryBot.create(:user, username: DEMO_USERNAME, email: DEMO_EMAIL, password: DEMO_PASSWORD)
    end

    def admin_user
      @admin_user ||= ::User.find_by(username: ADMIN_USERNAME) ||
                      FactoryBot.create(:user, :with_role, username: ADMIN_USERNAME, email: ADMIN_EMAIL,
                                                           password: ADMIN_PASSWORD)
    end

    def participants
      @participants ||= [demo_user] + Array.new(PARTICIPANT_COUNT - 1) { |index| ensure_participant(index) }
    end

    def ensure_participant(index)
      username = "demo_player_#{index + 1}"
      ::User.find_by(username:) ||
        FactoryBot.create(:user, username:, email: "#{username}@example.com", password: PARTICIPANT_PASSWORD)
    end

    def seed_draft(tournament)
      draft = ensure_draft(tournament)

      if tournament.starting_date.past?
        seed_completed_participations(draft)
      else
        seed_pending_participations(draft)
      end
    end

    def ensure_draft(tournament)
      ::SalaryDraft.find_by(tournament:) ||
        ::SalaryDraft.create!(tournament:, roster_size: ROSTER_SIZE, price_cap: price_cap_for(tournament))
    end

    def price_cap_for(tournament)
      calculator = Players::CostCalculator.new(pricing_rules: [Players::ScalingPriceRule.new])
      top_costs = tournament.game.players.map { |player| calculator.calculate_cost(player:, tournament:) }
                            .sort.last(ROSTER_SIZE)
      (top_costs.sum + PRICE_CAP_HEADROOM).round(2)
    end

    def seed_completed_participations(draft)
      participants.each_with_index { |user, index| seed_completed_participation(draft:, user:, offset: index * 7) }
    end

    def seed_completed_participation(draft:, user:, offset:)
      return if ::Participation.exists?(draft:, user:)

      participation = build_participation_with_roster(draft:, user:, offset:)
      ::SalaryDrafts::Scorer.call(participation:, draft:)
      participation.completed!
    end

    def seed_pending_participations(draft)
      seed_submitted_participation(draft:, user: participants.first)
      seed_created_participation(draft:, user: participants.second)
    end

    def seed_submitted_participation(draft:, user:)
      return if ::Participation.exists?(draft:, user:)

      build_participation_with_roster(draft:, user:, offset: 0).update!(status: 'submitted')
    end

    def seed_created_participation(draft:, user:)
      return if ::Participation.exists?(draft:, user:)

      ::Participation.create!(draft:, user:, status: 'created')
    end

    def build_participation_with_roster(draft:, user:, offset:)
      participation = ::Participation.create!(draft:, user:, status: 'created')
      players = chosen_players(tournament: draft.tournament, offset:)
      ::Roster.create!(participation:, roster_players_attributes: players.map { |player| { player: } })
      participation
    end

    def chosen_players(tournament:, offset:)
      tournament.game.players.order(:external_id).to_a.rotate(offset).first(ROSTER_SIZE)
    end

  end

end
