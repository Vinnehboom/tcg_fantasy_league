# Per-game composition root for +Game+. Each known game — PTCG today, more
# later — registers itself once: its id, a +Game.<name>+ finder scope, and
# whatever per-game collaborators it needs (currently its results verifier
# and its results-import job class). Callers ask a +Game+ instance for its
# own collaborator — `tournament.game.results_verifier`,
# `tournament.game.results_import_job` — instead of switching on its id, so
# onboarding a new game means one +register+ call here, not a new branch in
# a shared conditional elsewhere in the app.
module GameRegistry

  extend ActiveSupport::Concern

  class_methods do
    def register(scope_name, id:, results_verifier: nil, results_import_job: nil)
      define_singleton_method(scope_name) { find_by(id:) }
      registrations[id] = { results_verifier:, results_import_job: }
    end

    def registrations
      @registrations ||= {}
    end
  end

  # Wrapped the same way as ExternalData::ImportJob#adapter (H-9): a
  # configured verifier_builder lambda receives the registered verifier as a
  # lazy block, so an environment can swap in a different one — currently
  # only development does, to avoid a live HTTP call from the admin
  # "verify tournament id" flow. results_import_job stays a direct reader:
  # it names a job class, not a live call, so there is nothing to stand in
  # for.
  def results_verifier
    verifier_builder.call(game: self) { registered_verifier }
  end

  def results_import_job
    self.class.registrations.dig(id, :results_import_job)
  end

  private

  def verifier_builder
    Rails.application.config.x.external_data.verifier_builder
  end

  def registered_verifier
    self.class.registrations.dig(id, :results_verifier)
  end

end
